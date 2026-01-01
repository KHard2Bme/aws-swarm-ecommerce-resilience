#!/bin/bash
set -e

########################################
# Preconditions
########################################
if ! docker info | grep -q "Swarm: active"; then
  echo "ERROR: Docker Swarm is not active"
  exit 1
fi

########################################
# Create Overlay Network
########################################
docker network inspect swarm-net >/dev/null 2>&1 || \
docker network create \
  --driver overlay \
  --attachable \
  swarm-net

########################################
# Deploy FRONTEND (Workers Only)
########################################
docker service inspect frontend >/dev/null 2>&1 || \
docker service create \
  --name frontend \
  --constraint 'node.role==worker' \
  --replicas 2 \
  --publish published=80,target=80 \
  --network swarm-net \
  nginx

########################################
# Deploy CHECKOUT (Workers Only)
########################################
docker service inspect checkout >/dev/null 2>&1 || \
docker service create \
  --name checkout \
  --constraint 'node.role==worker' \
  --replicas 2 \
  --network swarm-net \
  nginx

########################################
# Deploy Prometheus (Manager Only)
########################################
docker service inspect prometheus >/dev/null 2>&1 || \
docker service create \
  --name prometheus \
  --constraint 'node.labels.role==manager' \
  --publish published=9090,target=9090 \
  --network swarm-net \
  prom/prometheus

########################################
# Deploy Grafana (Manager Only)
########################################
docker service inspect grafana >/dev/null 2>&1 || \
docker service create \
  --name grafana \
  --constraint 'node.labels.role==manager' \
  --publish published=3000,target=3000 \
  --network swarm-net \
  grafana/grafana

########################################
# Deploy Traffic Generator
########################################
docker service inspect traffic-generator >/dev/null 2>&1 || \
docker service create \
  --name traffic-generator \
  --constraint 'node.role==worker' \
  --replicas 1 \
  --network swarm-net \
  busybox \
  sh -c "while true; do wget -q -O- http://frontend; sleep 1; done"

echo "All services deployed successfully"
