###########################
# Default VPC & aws_subnets
###########################
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

#############################
# Security Group
#############################
resource "aws_security_group" "swarm_sg" {
  name        = "${var.project_name}-sg"
  description = "Docker Swarm + Monitoring"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Swarm Internal Communication"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "Allow SSH (restricted)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Grafana Access"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Prometheus Access"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

###############
# AMI
###############
data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  owners = ["amazon"]
}

#################
# Swarm Manager
#################
resource "aws_instance" "manager" {
  count         = var.manager_count
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  subnet_id     = data.aws_subnets.default.ids[0]
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.swarm_sg.id]

  user_data = file("user_data/manager.sh")

  tags = {
    Name = "${var.project_name}-manager"
  }
}

##################
# Swarm Workers
##################
resource "aws_instance" "worker" {
  count         = var.worker_count
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  subnet_id     = data.aws_subnets.default.ids[1]
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.swarm_sg.id]

  user_data = file("user_data/worker.sh")

  tags = {
    Name = "${var.project_name}-worker-${count.index}"
  }
}
