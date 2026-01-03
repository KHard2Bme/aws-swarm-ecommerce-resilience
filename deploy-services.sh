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
if ! docker service inspect frontend >/dev/null 2>&1; then
  docker service create \
    --name frontend \
    --constraint 'node.labels.role==worker' \
    --replicas 2 \
    --publish published=8081,target=80 \
    --network swarm-net \
    nginx
else
  echo "Frontend service already exists"
fi

########################################
# CHECKOUT Service (Workers Only)
########################################
if ! docker service inspect checkout >/dev/null 2>&1; then
  docker service create \
    --name checkout \
    --constraint 'node.labels.role==worker' \
    --replicas 2 \
    --publish published=8082,target=80 \
    --network swarm-net \
    nginx
else
  echo "Checkout service already exists"
fi

########################################
# PROMETHEUS (Manager Only)
########################################
if ! docker service inspect prometheus >/dev/null 2>&1; then
  docker service create \
    --name prometheus \
    --constraint 'node.labels.role==manager' \
    --publish published=9090,target=9090 \
    --network swarm-net \
    prom/prometheus
else
  echo "Prometheus service already exists"
fi

########################################
# GRAFANA (Manager Only)
########################################
if ! docker service inspect grafana >/dev/null 2>&1; then
  docker service create \
    --name grafana \
    --constraint 'node.labels.role==manager' \
    --publish published=3000,target=3000 \
    --network swarm-net \
    grafana/grafana
else
  echo "Grafana service already exists"
fi

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

echo "======================================"
echo " All services deployed successfully"
echo "======================================"

