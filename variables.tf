variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
}

variable "env" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-west-1a", "us-west-1b", "us-west-1c"]
}
