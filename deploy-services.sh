#!/bin/bash
set -e

# Create overlay network if not exists
docker network inspect swarm-net >/dev/null 2>&1 || \
docker network create --driver overlay --attachable swarm-net

# Frontend (Workers)
docker service rm frontend || true
docker service create \
  --name frontend \
  --constraint 'node.role==worker' \
  --replicas 2 \
  --publish published=8081,target=80 \
  --network swarm-net \
  194722415553.dkr.ecr.us-east-1.amazonaws.com/swarm-frontend1:1.0

# Checkout (Workers)
docker service rm checkout || true
docker service create \
  --name checkout \
  --constraint 'node.role==worker' \
  --replicas 2 \
  --publish published=8082,target=80 \
  --network swarm-net \
  194722415553.dkr.ecr.us-east-1.amazonaws.com/swarm-checkout1:1.0


