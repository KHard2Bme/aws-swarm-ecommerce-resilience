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

########################
# Save worker join token
########################
docker swarm join-token worker -q > /tmp/worker_join_token
chmod 644 /tmp/worker_join_token
