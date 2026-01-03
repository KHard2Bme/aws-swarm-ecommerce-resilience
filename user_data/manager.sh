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
  docker swarm init --advertise-addr "$PRIVATE_IP"
fi

########################################
# Label manager node
########################################
MANAGER_NODE_ID=$(docker info -f '{{.Swarm.NodeID}}')
docker node update --label-add role=manager "$MANAGER_NODE_ID"

########################################
# Expose worker join token
########################################
docker swarm join-token -q worker > /tmp/worker_join_token

cd /tmp
nohup python3 -m http.server 8080 >/var/log/token-server.log 2>&1 &

########################################
# Auto-label workers (background loop)
########################################
cat << 'EOF' > /usr/local/bin/label-workers.sh
#!/bin/bash
while true; do
  for NODE in $(docker node ls --format '{{.ID}} {{.Role}} {{.Hostname}}' | awk '$2=="worker" {print $1}'); do
    docker node inspect "$NODE" --format '{{ index .Spec.Labels "role" }}' | grep -q worker \
      || docker node update --label-add role=worker "$NODE"
  done
  sleep 20
done
EOF

chmod +x /usr/local/bin/label-workers.sh
nohup /usr/local/bin/label-workers.sh >/var/log/worker-labeler.log 2>&1 &


