variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "key_name" {
  description = "EC2 key pair name"  
  type        = string
  default     = "LUIT_Linux1_Keys"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "manager_count" {
  type    = number
  default = 1
}

variable "worker_count" {
  type    = number
  default = 2
}

variable "project_name" {
  type    = string
  default = "swarm-ecommerce"
}
