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
# Join Docker Swarm
#################################
MANAGER_PRIVATE_IP="${manager_private_ip}"

# Retry until manager is ready
for i in {1..10}; do
  docker swarm join \
    --token "${worker_join_token}" \
    ${MANAGER_PRIVATE_IP}:2377 && break
  sleep 15
done

#################################
# Label Worker Node
#################################
docker node update --label-add role=worker $(hostname)

