variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = secrets.AWS_REGION
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = secrets.VPC_CIDR_BLOCK
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = secrets.PUBLIC_SUBNET_CIDRS
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = secrets.PRIVATE_SUBNET_CIDRS
}

variable "env" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
  default     = secrets.ENV
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = secrets.AVAILABILITY_ZONES
}
variable "security_group_name" {
  description = "The name of the security group"
  type        = list(string)
  default     = secrets.SECURITY_GROUP_NAME
}

variable "instance_type" {
  description = "The type of EC2 instance"
  type        = string
  default     = secrets.INSTANCE_TYPE
}

variable "ami_id" {
  description = "The AMI ID for the EC2 instance"
  type        = string
  default     = secrets.AMI_ID
}