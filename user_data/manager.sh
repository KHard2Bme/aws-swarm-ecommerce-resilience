#!/bin/bash
set -e

#################################
# Install Docker
#################################
yum update -y
amazon-linux-extras install docker -y
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user

#################################
# Initialize Docker Swarm
#################################
PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

if ! docker info | grep -q "Swarm: active"; then
  docker swarm init --advertise-addr $PRIVATE_IP
fi

#################################
# Label Manager Node
#################################
NODE_ID=$(docker info -f '{{.Swarm.NodeID}}')
docker node update --label-add role=manager $NODE_ID

#################################
# Create Overlay Network
#################################
docker network inspect swarm-net >/dev/null 2>&1 || \
docker network create \
  --driver overlay \
  --attachable \
  swarm-net

#################################
# Deploy Prometheus
#################################
docker service inspect prometheus >/dev/null 2>&1 || \
docker service create \
  --name prometheus \
  --constraint 'node.labels.role==manager' \
  --publish published=9090,target=9090 \
  --network swarm-net \
  prom/prometheus

#################################
# Deploy Grafana
#################################
docker service inspect grafana >/dev/null 2>&1 || \
docker service create \
  --name grafana \
  --constraint 'node.labels.role==manager' \
  --publish published=3000,target=3000 \
  --network swarm-net \
  grafana/grafana

#################################
# Output Join Token (for debugging)
#################################
docker swarm join-token worker
