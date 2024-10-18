# Output the VPC ID
output "vpc_id" {
  value =  aws_vpc.main_vpc.id
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
