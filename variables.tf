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

variable "instance_type" {
  description = "The type of EC2 instance"
  type        = string
  default     = "t2.micro"
}

variable "ami_id" {
  description = "The AMI ID for the EC2 instance"
  type        = string

}

variable "db_user" {
  description = "The username for the database"
  type        = string
}

variable "db_database" {
  description = "The database name"
  type        = string
}

variable "db_password" {
  description = "The password for the database"
  type        = string
}


variable "db_port" {
  description = "The port for the database"
  type        = number
  default     = 5432
}

variable "app_port" {
  description = "The port for the application"
  type        = number
  default     = 9001

}

variable "domain_name" {
  description = "The domain name for the instance"
  type        = string
}

variable "record_type" {
  description = "The record type for the instance"
  type        = string
}

variable "aws_access_key" {
  description = "The AWS access key"
  type        = string
}

variable "aws_secret_key" {
  description = "The AWS secret key"
  type        = string
}

variable "key_name" {
  description = "The key name for the EC2 instance"
  type        = string
}

variable "assignment" {
  description = "The assignment name"
  type        = string
}

variable "low_cpu_alarm_name" {
  description = "The name of the low CPU alarm"
  type        = string
}

variable "low_cpu_comparison_operator" {
  description = "The comparison operator for the low CPU alarm"
  type        = string
}

variable "evaluation_periods" {
  description = "The number of evaluation periods for the alarm"
  type        = string
}

variable "metric_name" {
  description = "The name of the metric to monitor"
  type        = string
}

variable "namespace" {
  description = "The namespace for the metric"
  type        = string
}

variable "period" {
  description = "The period for the alarm"
  type        = string
}

variable "statistic" {
  description = "The statistic to use for the alarm"
  type        = string
}


variable "low_cpu_threshold" {
  description = "The threshold for the low CPU alarm"
  type        = string
}

variable "high_cpu_threshold" {
  description = "The threshold for the high CPU alarm"
  type        = string
}

variable "alarm_description" {
  description = "The description for the alarm"
  type        = string
}

variable "high_cpu_alarm_name" {
  description = "The name of the high CPU alarm"
  type        = string
}

variable "high_cpu_comparison_operator" {
  description = "The comparison operator for the high CPU alarm"
  type        = string
}

variable "protocol" {
  description = "The protocol for the health check"
  type        = string
}

variable "cooldown" {
  description = "The cooldown period for the alarm"
  type        = number
}

variable "adjustment_type" {
  description = "The adjustment type for the alarm"
  type        = string
}

variable "metric_aggregation_type" {
  description = "The aggregation type for the alarm"
  type        = string
}