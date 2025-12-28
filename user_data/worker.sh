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
MANAGER_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4 | sed 's/\.[0-9]*$/.1/')

for i in {1..15}; do
  TOKEN=$(ssh -o StrictHostKeyChecking=no ec2-user@${MANAGER_IP} "cat /tmp/worker_join_token" 2>/dev/null)
  if [ -n "$TOKEN" ]; then
    docker swarm join --token "$TOKEN" ${MANAGER_IP}:2377 && break
  fi
  sleep 15
done

