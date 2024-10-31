# Output the VPC ID
output "vpc_id" {
  value = aws_vpc.main_vpc.id
}

# Output the Public Subnet IDs
output "public_subnet_ids" {
  value = aws_subnet.public_subnet[*].id
}


# Output the Private Subnet IDs
output "private_subnet_ids" {
  value = aws_subnet.private_subnet[*].id
}

# Output the Internet Gateway ID
output "internet_gateway_id" {
  value = aws_internet_gateway.igw.id
}

output "s3_bucket_name" {
  value       = aws_s3_bucket.private_webapp_bucket.bucket
  description = "The name of the S3 bucket used for storing images"
}

output "rds_endpoint" {
  value       = aws_db_instance.csye6225_db.address
  description = "The endpoint of the RDS instance"
}