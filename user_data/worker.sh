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
MANAGER_IP="${manager_private_ip}"

##################
# Wait for Docker
##################
sleep 30

#############################
# Retry join until successful
#############################
for i in {1..15}; do
  TOKEN=$(ssh -o StrictHostKeyChecking=no ec2-user@$MANAGER_IP \
    docker swarm join-token -q worker || true)

  if [ -n "$TOKEN" ]; then
    docker swarm join --token $TOKEN $MANAGER_IP:2377 && break
  fi

  sleep 15
done
