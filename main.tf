###########################
# Default VPC & aws_subnets
###########################
data "aws_vpc" "default" {
  default = true
}

data "aws_availability_zones" "supported" {
  state = "available"

  filter {
    name   = "zone-name"
    values = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d", "us-east-1f"]
  }
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "availability-zone"
    values = data.aws_availability_zones.supported.names
  }
}


#############################
# Security Groups
#############################
resource "aws_security_group" "manager_sg" {
  name   = "${var.project_name}-manager-sg"
  vpc_id = data.aws_vpc.default.id

 ingress {
    description = "Allow SSH (restricted)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

ingress {
  description = "Workers join token HTTP access"
  from_port   = 8080
  to_port     = 8080
  protocol    = "tcp"
  security_groups = [aws_security_group.worker_sg.id]
}

ingress {
    description = "Docker Swarm join from Workers"
    from_port   = 2377
    to_port     = 2377
    protocol    = "tcp"
    security_groups = [aws_security_group.worker_sg.id]
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


resource "aws_security_group" "worker_sg" {
  name   = "${var.project_name}-worker-sg"
  vpc_id = data.aws_vpc.default.id

    ingress {
    description = "Allow SSH (restricted)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
  description = "Internal SSH for Swarm bootstrap"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  self        = true
}

  ingress {
    description = "Allow HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Docker Swarm Manager"
    from_port   = 2377
    to_port     = 2377
    protocol    = "tcp"
    self        = true
  }

ingress {
    description = "Docker Swarm Node Discovery"
    from_port   = 7946
    to_port     = 7946
    protocol    = "tcp"
    self        = true
  }

ingress {
    description = "Docker Swarm Node Discovery (UDP)"
    from_port   = 7946
    to_port     = 7946
    protocol    = "udp"
    self        = true
  }

ingress {
    description = "Docker Swarm Overlay Network (UDP)"
    from_port   = 4789
    to_port     = 4789
    protocol    = "udp"
    self        = true
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
  subnet_id     = data.aws_subnets.default.ids[count.index]
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.manager_sg.id]

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

  subnet_id = data.aws_subnets.default.ids[
    count.index % length(data.aws_subnets.default.ids)
  ]

  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.worker_sg.id]

  user_data = templatefile(
  "${path.module}/user_data/worker.sh",
  {
    manager_private_ip = aws_instance.manager[0].private_ip
  }
)

  tags = {
    Name = "${var.project_name}-worker-${count.index}"
  }
}


#######
# ALB
#######
resource "aws_lb" "alb" {
  name               = var.alb_name
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default.ids
  security_groups    = [aws_security_group.worker_sg.id]
}

###############
# Target Group
###############
resource "aws_lb_target_group" "swarm_tg" {
  name     = "${var.project_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

##########################################
# Target Group Attachments (All EC2 Nodes)
##########################################
resource "aws_lb_target_group_attachment" "workers" {
  count            = var.worker_count
  target_group_arn = aws_lb_target_group.swarm_tg.arn
  target_id        = aws_instance.worker[count.index].id
  port             = 80
}

###########
# Listener
###########
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.swarm_tg.arn
  }
}
