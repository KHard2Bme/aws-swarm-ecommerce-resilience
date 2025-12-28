#!/bin/bash
set -e

########################################
# Install Docker
########################################
yum update -y
amazon-linux-extras install docker -y
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user

########################################
# Initialize Docker Swarm (Idempotent)
########################################
PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

if ! docker info | grep -q "Swarm: active"; then
  docker swarm init --advertise-addr $PRIVATE_IP
fi

########################################
# Label Manager Node
########################################
NODE_ID=$(docker info -f '{{.Swarm.NodeID}}')
docker node update --label-add role=manager $NODE_ID || true

########################################
# Wait for Workers to Join
########################################
echo "Waiting for workers to join..."
for i in {1..18}; do
  WORKERS=$(docker node ls --format '{{.Hostname}} {{.ManagerStatus}}' | grep -v Leader | wc -l)
  if [ "$WORKERS" -ge 1 ]; then
    echo "Workers joined: $WORKERS"
    break
  fi
  sleep 10
done

########################################
# Label Worker Nodes (Manager-only)
########################################
docker node ls --format '{{.ID}} {{.ManagerStatus}}' \
  | grep -v Leader \
  | awk '{print $1}' \
  | xargs -r docker node update --label-add role=worker

########################################
# Create Overlay Network
########################################
docker network inspect swarm-net >/dev/null 2>&1 || \
docker network create --driver overlay --attachable swarm-net

########################################
# Deploy FRONTEND (Workers Only)
########################################
docker service inspect frontend >/dev/null 2>&1 || \
docker service create \
  --name frontend \
  --constraint 'node.labels.role==worker' \
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
  --constraint 'node.labels.role==worker' \
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
