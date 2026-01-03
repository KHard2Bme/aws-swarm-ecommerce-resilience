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
    from_port   = 3000
    to_port     = 3000
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
    from_port       = 8081
    to_port         = 8081
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    description     = "Checkout from ALB"
    from_port       = 8082
    to_port         = 8082
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
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
  subnet_id              = data.aws_subnets.default.ids[count.index]
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
  port     = 8081
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
}

resource "aws_lb_target_group" "checkout_tg" {
  name     = "${var.project_name}-checkout-tg"
  port     = 8082
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
}

#############################
# Attach Workers
#############################
resource "aws_lb_target_group_attachment" "frontend" {
  count            = var.worker_count
  target_group_arn = aws_lb_target_group.frontend_tg.arn
  target_id        = aws_instance.worker[count.index].id
  port             = 8081
}

resource "aws_lb_target_group_attachment" "checkout" {
  count            = var.worker_count
  target_group_arn = aws_lb_target_group.checkout_tg.arn
  target_id        = aws_instance.worker[count.index].id
  port             = 8082
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

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.checkout_tg.arn
  }

  condition {
    path_pattern {
      values = ["/checkout*"]
    }
  }
}
