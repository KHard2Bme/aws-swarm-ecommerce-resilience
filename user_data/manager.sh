#!/bin/bash
yum update -y
amazon-linux-extras install docker -y
systemctl start docker
usermod -aG docker ec2-user

docker swarm init

# Monitoring stack
docker service create --name prometheus -p 9090:9090 prom/prometheus
docker service create --name grafana -p 3000:3000 grafana/grafana

# E-commerce services (simplified)
docker service create --name frontend -p 80:80 nginx
docker service create --name checkout --replicas 2 hashicorp/http-echo -text="Checkout OK"

# Synthetic Traffic Generator
docker service create \
  --name traffic-generator \
  --replicas 5 \
  curlimages/curl \
  sh -c "while true; do curl -s http://frontend; sleep 1; done"
