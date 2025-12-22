variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "key_name" {
  description = "EC2 key pair name"
  type        = "LUIT_Linux1_Keys"
}

variable "instance_type" {
  default = "t3.micro"
}

variable "manager_count" {
  default = 1
}

variable "worker_count" {
  default = 2
}

variable "project_name" {
  default = "swarm-ecommerce"
}
