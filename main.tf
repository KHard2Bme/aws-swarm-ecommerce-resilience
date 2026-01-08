###########################
# VPC & Subnets
###########################
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "availability-zone"
    values = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d", "us-east-1f"]
  }
}

#############################
# ALB Security Group (PUBLIC)
#############################
resource "aws_security_group" "alb_sg" {
  name   = "${var.project_name}-alb-sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    description = "Public HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#############################
# Manager Security Group
#############################
resource "aws_security_group" "manager_sg" {
  name   = "${var.project_name}-manager-sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description     = "Worker Join Token"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.worker_sg.id]
  }

  ingress {
    description     = "Swarm Manager"
    from_port       = 2377
    to_port         = 2377
    protocol        = "tcp"
    security_groups = [aws_security_group.worker_sg.id]
  }

  ingress {
    description = "Grafana"
    from_port   = 3100
    to_port     = 3100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Prometheus"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#############################
# Worker Security Group (PRIVATE)
#############################
resource "aws_security_group" "worker_sg" {
  name   = "${var.project_name}-worker-sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    description = "SSH (admin)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #################################
  # ALB → Services (ONLY)
  #################################
  ingress {
  description     = "Frontend from ALB"
  from_port       = 3000
  to_port         = 3000
  protocol        = "tcp"
  security_groups = [aws_security_group.alb_sg.id]
}

ingress {
  description     = "Checkout from ALB"
  from_port       = 3001
  to_port         = 3001
  protocol        = "tcp"
  security_groups = [aws_security_group.alb_sg.id]
}

###################################################
# Prometheus needs to scrape node-exporter/cAdvisor
###################################################
ingress {
  description     = "Node Exporter from Manager"
  from_port       = 9100
  to_port         = 9100
  protocol        = "tcp"
  cidr_blocks = [data.aws_vpc.default.cidr_block]
}

ingress {
  description     = "cAdvisor from Manager"
  from_port       = 8080
  to_port         = 8080
  protocol        = "tcp"
  cidr_blocks = [data.aws_vpc.default.cidr_block]
}


   #################################
  # Docker Swarm Internal
  #################################
  ingress {
    description     = "Docker Swarm Manager"
    from_port       = 2377
    to_port         = 2377
    protocol        = "tcp"
    self            = true
  }

  ingress {
    description     = "Docker Swarm Node Discovery"
    from_port       = 7946
    to_port         = 7946
    protocol        = "tcp"
    self            = true
  }

  ingress {
    description = "Docker Swarm Node Discovery"
    from_port   = 7946
    to_port     = 7946
    protocol    = "udp"
    self        = true
  }

  ingress {
    description = "Docker Swarm Overlay Network"
    from_port   = 4789
    to_port     = 4789
    protocol    = "udp"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

########################
# Amazon Linux 2 AMI
########################
data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

#############################
# EC2 Instances
#############################
resource "aws_instance" "manager" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnets.default.ids[0]
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.manager_sg.id]
  user_data              = file("user_data/manager.sh")

  tags = {
    Name = "${var.project_name}-manager"
  }
}

resource "aws_instance" "worker" {
  count                  = var.worker_count
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnets.default.ids[
    count.index % length(data.aws_subnets.default.ids)
  ]
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.worker_sg.id]

  user_data = templatefile("${path.module}/user_data/worker.sh", {
    manager_private_ip = aws_instance.manager.private_ip
  })

  tags = {
    Name = "${var.project_name}-worker-${count.index}"
  }
}

#############################
# Application Load Balancer
#############################
resource "aws_lb" "alb" {
  name               = var.alb_name
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default.ids
  security_groups    = [aws_security_group.alb_sg.id]
}

#############################
# Target Groups
#############################
resource "aws_lb_target_group" "frontend_tg" {
  name     = "${var.project_name}-frontend-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path = "/"
  }
}

resource "aws_lb_target_group" "checkout_tg" {
  name     = "${var.project_name}-checkout-tg"
  port     = 3001
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/checkout"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

#############################
# Attach Workers
#############################
resource "aws_lb_target_group_attachment" "frontend" {
  count            = var.worker_count
  target_group_arn = aws_lb_target_group.frontend_tg.arn
  target_id        = aws_instance.worker[count.index].id
  port             = 3000
}

resource "aws_lb_target_group_attachment" "checkout" {
  count            = var.worker_count
  target_group_arn = aws_lb_target_group.checkout_tg.arn
  target_id        = aws_instance.worker[count.index].id
  port             = 3001
}

#############################
# ALB Listener & Routing
#############################
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }
}

resource "aws_lb_listener_rule" "checkout" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  condition {
    path_pattern {
      values = ["/checkout*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.checkout_tg.arn
  }
}

