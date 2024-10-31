provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "main_vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "terraform-vpc"
  }
}

# Create public subnets in different AZs
resource "aws_subnet" "public_subnet" {
  count                   = 3
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr_block, 4, count.index)
  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-${count.index + 1}"
  }
}

# Create private subnets in different AZs
resource "aws_subnet" "private_subnet" {
  count             = 3
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr_block, 4, count.index + 4)
  availability_zone = element(var.availability_zones, count.index)
  tags = {
    Name = "private-subnet-${count.index + 1}"
  }
}


resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = "main_igw"
  }
}

# Create Public Route Table
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public_route_table"
  }
}

# Create Private Route Table
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = "private_route_table"
  }
}

# Associate Public Subnets with Public Route Table
resource "aws_route_table_association" "public_route_table_assoc" {
  count          = 3
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

# Associate Private Subnets with Private Route Table
resource "aws_route_table_association" "private_route_table_assoc" {
  count          = 3
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_security_group" "app_security_group" {
  name        = "application-security-group"
  description = "Security group for EC2 instances hosting webapp"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow application traffic"
    from_port   = 9001
    to_port     = 9001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "application security group"
  }
}


resource "aws_instance" "webapp_instance" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.app_security_group.id]
  subnet_id              = element(aws_subnet.public_subnet[*].id, 0)
  iam_instance_profile   = aws_iam_instance_profile.ec2_role_profile.name


  root_block_device {
    volume_size           = 25
    volume_type           = "gp2"
    delete_on_termination = true
  }

  disable_api_termination = false

  tags = {
    Name = "WebAppInstance"
  }
  associate_public_ip_address = true
  depends_on                  = [aws_db_instance.csye6225_db]

  user_data = base64encode(<<-EOF
            #!/bin/bash
            echo "DB_HOST=${aws_db_instance.csye6225_db.address}" >> /opt/webapp/.env
            echo "DB_USER=csye6225" >> /opt/webapp/.env
            echo "DB_PASSWORD=${var.db_password}" >> /opt/webapp/.env
            echo "DB_DATABASE=csye6225" >> /opt/webapp/.env
            echo "DB_PORT=${var.db_port}" >> /opt/webapp/.env
            echo "S3_BUCKET_NAME=${aws_s3_bucket.private_webapp_bucket.bucket}" >> /opt/webapp/.env
            echo "AWS_REGION=${var.aws_region}" >> /opt/webapp/.env
            echo "AWS_ACCESS_KEY_ID=${var.aws_access_key}" >> /opt/webapp/.env
            echo "AWS_SECRET_ACCESS_KEY=${var.aws_secret_key}" >> /opt/webapp/.env
            echo "AWS_OUTPUT_FORMAT=json" >> /opt/webapp/.env
            sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
            -a fetch-config \
            -m ec2 \
            -c file:/opt/webapp/cloud-watch-config.json \
            -s
            sudo chmod 644 /opt/webapp/cloud-watch-config.json
            sudo chown root:root /opt/webapp/cloud-watch-config.json
            sudo systemctl enable amazon-cloudwatch-agent
            sudo systemctl start amazon-cloudwatch-agent
            sudo systemctl status amazon-cloudwatch-agent
            sudo systemctl enable mywebapp.service
            sudo systemctl start mywebapp.service
            sudo systemctl status mywebapp.service
            sudo systemctl daemon-reload
            EOF
  )

}

## for database instance
# Database Security Group
resource "aws_security_group" "database_sg" {
  name        = "database-security-group"
  description = "Security group for RDS instances"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description     = "Allow inbound traffic from application security group"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app_security_group.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Database Security Group"
  }
}

# RDS Parameter Group
resource "aws_db_parameter_group" "custom_pg" {
  family = "postgres14" # Change this to match your database engine and version
  name   = "csye6225-custom-pg"

  parameter {
    name         = "max_connections"
    value        = "100"
    apply_method = "pending-reboot"
  }
}

# RDS Subnet Group
resource "aws_db_subnet_group" "private_subnet_group" {
  name       = "csye6225-private-subnet-group"
  subnet_ids = aws_subnet.private_subnet[*].id

  tags = {
    Name = "CSYE6225 Private Subnet Group"
  }
}

# RDS Instance
resource "aws_db_instance" "csye6225_db" {
  identifier             = "csye6225"
  engine                 = "postgres"
  engine_version         = "14"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  storage_type           = "gp2"
  multi_az               = false
  db_name                = "csye6225"
  username               = "csye6225"
  password               = var.db_password
  parameter_group_name   = aws_db_parameter_group.custom_pg.name
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.database_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.private_subnet_group.name
  publicly_accessible    = false

  tags = {
    Name = "CSYE6225 Database"
  }
}

# S3 bucket
# Generate a random UUID for the bucket name
resource "random_id" "bucket_name" {
  byte_length = 7
}

resource "aws_s3_bucket" "private_webapp_bucket" {
  bucket = random_id.bucket_name.hex

  # Force deletion of non-empty bucket
  force_destroy = true

  tags = {
    Name        = "S3 Bucket"
    Environment = "S3 Bucket"
  }
}

# Lifecycle policy for transitioning to STANDARD_IA after 30 days
resource "aws_s3_bucket_lifecycle_configuration" "s3_lifecycle_config" {
  bucket = aws_s3_bucket.private_webapp_bucket.id

  rule {
    id = "lifecycle"
    filter {}

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    status = "Enabled"
  }

}

# Enable default encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "s3_key_encryption" {
  bucket = aws_s3_bucket.private_webapp_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# IAM Role for for ec2 to access S3 bucket
resource "aws_iam_role" "s3_access_role_to_ec2" {
  name = "CSYE6225-S3BucketAccessRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Sid    = "RoleForEC2",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# IAM Policy for S3 Bucket Access and cloudwatch access
resource "aws_iam_policy" "s3_access_policy" {
  name        = "WebappS3AccessPolicy"
  description = "Policy for accessing the private S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ],
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.private_webapp_bucket.arn}/*",
          "arn:aws:s3:::${aws_s3_bucket.private_webapp_bucket.bucket}"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "cloudwatch:PutLogEvents",
          "logs:*"
        ],
        Resource = "*"
      }
    ]
  })
}

# Get the policy by name
data "aws_iam_policy" "cloudwatch_policy" {
  name = "CloudWatchAgentServerPolicy"
}

//attaching the policy to ec2 role
resource "aws_iam_policy_attachment" "policy_role_attach" {
  name       = "policy_role_attach"
  roles      = [aws_iam_role.s3_access_role_to_ec2.name]
  policy_arn = aws_iam_policy.s3_access_policy.arn
}


//attaching the policy to cloudwatch
resource "aws_iam_policy_attachment" "policy_role_attach_cloudwatch" {
  name       = "policy_role_attach_cloudwatch"
  roles      = [aws_iam_role.s3_access_role_to_ec2.name]
  policy_arn = data.aws_iam_policy.cloudwatch_policy.arn
}

//attaching the policy to ec2 role
resource "aws_iam_instance_profile" "ec2_role_profile" {
  name = "ec2_role_profile"
  role = aws_iam_role.s3_access_role_to_ec2.name
}

//public access block
resource "aws_s3_bucket_public_access_block" "s3_bucket_public_access_block" {
  bucket = aws_s3_bucket.private_webapp_bucket.bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

//AWS Route 53 zone data source
data "aws_route53_zone" "selected_zone" {
  name         = var.domain_name
  private_zone = false
}

//AWS Route 53 A record
resource "aws_route53_record" "server_mapping_record" {
  zone_id = data.aws_route53_zone.selected_zone.zone_id
  name    = var.domain_name
  type    = var.record_type
  records = [aws_instance.webapp_instance.public_ip]
  ttl     = var.ttl
}