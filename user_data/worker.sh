#!/bin/bash
set -e

#################################
# Install Docker
#################################
yum update -y
amazon-linux-extras install docker -y
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user

#################################
# Join Docker Swarm
#################################
MANAGER_PRIVATE_IP="${manager_private_ip}"
WORKER_TOKEN="${worker_join_token}"

for i in {1..15}; do
  docker swarm join \
    --token "${WORKER_TOKEN}" \
    ${MANAGER_PRIVATE_IP}:2377 && break
  sleep 15
done
