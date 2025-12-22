#!/bin/bash
yum update -y
amazon-linux-extras install docker -y
systemctl start docker
usermod -aG docker ec2-user

# Workers join manually after init (realistic ops model)
