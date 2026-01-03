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

sleep 60

for i in {1..20}; do
  TOKEN=$(curl -s http://$MANAGER_IP:8080/worker_join_token || true)
  if [ -n "$TOKEN" ]; then
    docker swarm join --token "$TOKEN" "$MANAGER_IP:2377" && break
  fi
  sleep 15
done

