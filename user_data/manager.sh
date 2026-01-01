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
# Initialize Docker Swarm 
########################################
PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

if ! docker info | grep -q "Swarm: active"; then
  docker swarm init --advertise-addr $PRIVATE_IP
fi

########################################
# Expose Worker Join Token (HTTP)
########################################
docker swarm join-token -q worker > /tmp/worker_join_token

cd /tmp
nohup python3 -m http.server 8080 >/var/log/token-server.log 2>&1 &

##############################
# Add node labeling to manager
##############################
NODE_ID=$(docker info -f '{{.Swarm.NodeID}}')
docker node update --label-add role=manager $NODE_ID

