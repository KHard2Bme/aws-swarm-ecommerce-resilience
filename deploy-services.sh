#!/bin/bash
set -e

########################################
# Preconditions
########################################
if ! docker info | grep -q "Swarm: active"; then
  echo "ERROR: Docker Swarm is not active on this node"
  exit 1
fi

echo "Docker Swarm is active"

########################################
# Create Overlay Network (idempotent)
########################################
docker network inspect swarm-net >/dev/null 2>&1 || \
docker network create \
  --driver overlay \
  --attachable \
  swarm-net

echo "Overlay network ready"

########################################
# FRONTEND Service (Workers Only)
# Published ONLY for ALB access
########################################
docker service create \
  --name frontend \
  --constraint 'node.role==worker' \
  --replicas 2 \
  --publish mode=host,published=3000,target=80 \
  --network swarm-net \
  194722415553.dkr.ecr.us-east-1.amazonaws.com/swarm-frontend2:1.0

########################################
# CHECKOUT Service (Workers Only)
########################################
docker service create \
  --name checkout \
  --constraint 'node.role==worker' \
  --replicas 2 \
  --publish mode=host,published=3001,target=80 \
  --network swarm-net \
  194722415553.dkr.ecr.us-east-1.amazonaws.com/swarm-checkout2:1.0


echo "Frontend available on /"
echo "Checkout available on /checkout"

########################################
# TRAFFIC GENERATOR (Workers Only)
########################################
if ! docker service inspect traffic-generator >/dev/null 2>&1; then
  docker service create \
    --name traffic-generator \
    --constraint 'node.labels.role==worker' \
    --replicas 1 \
    --network swarm-net \
    busybox \
    sh -c "while true; do wget -q -O- http://frontend; sleep 1; done"
else
  echo "Traffic generator already exists"
fi

########################################
# Node Exporter (ALL NODES)
########################################
docker service create \
  --name node-exporter \
  --mode global \
  --network swarm-net \
  --constraint 'node.platform.os == linux' \
  --mount type=bind,src=/proc,dst=/host/proc,ro \
  --mount type=bind,src=/sys,dst=/host/sys,ro \
  --mount type=bind,src=/,dst=/rootfs,ro \
  prom/node-exporter \
  --path.procfs=/host/proc \
  --path.sysfs=/host/sys \
  --path.rootfs=/rootfs

########################################
# cAdvisor (ALL NODES)
########################################
docker service create \
  --name cadvisor \
  --mode global \
  --network swarm-net \
  --mount type=bind,src=/,dst=/rootfs,ro \
  --mount type=bind,src=/var/run,dst=/var/run,ro \
  --mount type=bind,src=/sys,dst=/sys,ro \
  --mount type=bind,src=/var/lib/docker,dst=/var/lib/docker,ro \
  gcr.io/cadvisor/cadvisor:latest

########################################
# Prometheus (MANAGER ONLY)
########################################
docker service create \
  --name prometheus \
  --constraint 'node.labels.role==manager' \
  --publish published=9090,target=9090 \
  --mount type=bind,src=/opt/prometheus/prometheus.yml,dst=/etc/prometheus/prometheus.yml \
  --network swarm-net \
  prom/prometheus

########################################
# Grafana (MANAGER ONLY)
########################################
docker service create \
  --name grafana \
  --constraint 'node.labels.role==manager' \
  --publish published=3100,target=3100 \
  --network swarm-net \
  grafana/grafana


echo "======================================"
echo " All services deployed successfully"
echo "======================================"


