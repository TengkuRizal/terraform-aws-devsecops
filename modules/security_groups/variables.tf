variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "admin_cidr" {
  description = "Admin IP CIDR for SSH"
  type        = string
}
