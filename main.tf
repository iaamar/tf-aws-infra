provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "main_vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "${var.assignment} - terraform-vpc"
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
    Name = "${var.assignment} - main_igw"
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
  name        = var.app_security_group_name
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
    description     = "Allow application traffic"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.load_balancer_sg.id]
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

# Database Security Group
resource "aws_security_group" "database_sg" {
  name        = var.db_security_group_name
  description = "Security group for RDS instances"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description     = "Allow inbound traffic from application security group"
    from_port       = var.db_port
    to_port         = var.db_port
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
  family = "postgres14"
  name   = "csye6225-custom-pg"

  parameter {
    name         = "max_connections"
    value        = "100"
    apply_method = "pending-reboot"
  }
}

# RDS Subnet Group
resource "aws_db_subnet_group" "private_subnet_group" {
  name       = var.db_subnet_group_name
  subnet_ids = aws_subnet.private_subnet[*].id

  tags = {
    Name = "CSYE6225 Private Subnet Group"
  }
}

# RDS Instance
resource "aws_db_instance" "csye6225_db" {
  identifier             = var.db_database
  engine                 = var.db_engine
  engine_version         = var.db_engine_version
  instance_class         = var.db_instance_class
  allocated_storage      = var.db_storage_size
  storage_type           = var.db_storage_type
  multi_az               = false
  db_name                = var.db_database
  username               = var.db_user
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
    Name = "${var.assignment} - S3 Bucket"
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
  name         = "${var.env}${var.domain_name}"
  private_zone = false
}

//AWS Route 53 A record
resource "aws_route53_record" "server_mapping_record" {
  zone_id = data.aws_route53_zone.selected_zone.zone_id
  name    = "${var.env}${var.domain_name}"
  type    = var.record_type
  # records = [aws_instance.webapp_instance.public_ip]
  # ttl = var.ttl

  alias {
    name                   = aws_lb.app_load_balancer.dns_name
    zone_id                = aws_lb.app_load_balancer.zone_id
    evaluate_target_health = true
  }
  depends_on = [aws_lb.app_load_balancer]
}


# Load Balancer Security Group
resource "aws_security_group" "load_balancer_sg" {
  name        = var.lb_sg_name
  description = "Security group for Load Balancer"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "Allow HTTP traffic from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS traffic from anywhere"
    from_port   = 443
    to_port     = 443
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

# Load Balancer
resource "aws_lb" "app_load_balancer" {
  name               = var.lb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load_balancer_sg.id]
  subnets            = [for subnet in aws_subnet.public_subnet : subnet.id]

  tags = {
    Name = "${var.assignment} - AppLoadBalancer"
  }
}

# IAM Role for Auto-Scaling Group
resource "aws_iam_role" "autoscaling_role" {
  name = "autoscaling-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "autoscaling.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}


# Target Group for Auto-Scaling
resource "aws_lb_target_group" "app_target_group" {
  name     = var.target_group_name
  port     = var.app_port
  protocol = var.protocol
  vpc_id   = aws_vpc.main_vpc.id

  health_check {
    enabled             = true
    path                = "/healthz"
    port                = var.app_port
    protocol            = var.protocol
    interval            = 120
    timeout             = 8
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.assignment} - AppTargetGroup"
  }
}

# Listener for Load Balancer
resource "aws_lb_listener" "app_lb_listener" {
  load_balancer_arn = aws_lb.app_load_balancer.arn
  port              = 80
  protocol          = var.protocol

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_target_group.arn
  }
}

# Launch Template for Auto-Scaling Group
resource "aws_launch_template" "app_launch_template" {
  name          = var.launch_template_name
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.app_security_group.id]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_role_profile.name
  }

  user_data = base64encode(templatefile("user-data.sh", {
    DB_HOST        = aws_db_instance.csye6225_db.address
    DB_USER        = var.db_user
    DB_PASSWORD    = var.db_password
    DB_DATABASE    = var.db_database
    DB_PORT        = var.db_port
    S3_BUCKET_NAME = aws_s3_bucket.private_webapp_bucket.bucket
    AWS_REGION     = var.aws_region
    AWS_ACCESS_KEY = var.aws_access_key
    AWS_SECRET_KEY = var.aws_secret_key
    SNS_TOPIC_ARN  = aws_sns_topic.user_verification.arn
  }))
}

# Auto-Scaling Group
resource "aws_autoscaling_group" "app_asg" {
  name                = "csye6225-asg"
  desired_capacity    = var.desired_capacity
  max_size            = var.max_size
  min_size            = var.min_size
  vpc_zone_identifier = [for subnet in aws_subnet.public_subnet : subnet.id]
  launch_template {
    id      = aws_launch_template.app_launch_template.id
    version = "$Latest"
  }
  target_group_arns         = [aws_lb_target_group.app_target_group.arn]
  health_check_type         = "EC2"
  health_check_grace_period = var.health_check_grace_period

  tag {
    key                 = "CSYE6225 - AutoScalingGroup"
    value               = "${var.assignment} - AutoScalingGroup"
    propagate_at_launch = true
  }
}

# Scale Up Policy
resource "aws_autoscaling_policy" "scale_up" {
  name                    = "scale-up"
  scaling_adjustment      = 1
  adjustment_type         = var.adjustment_type
  cooldown                = var.cooldown
  autoscaling_group_name  = aws_autoscaling_group.app_asg.name
  metric_aggregation_type = var.metric_aggregation_type
}

# Scale Down Policy
resource "aws_autoscaling_policy" "scale_down" {
  name                    = "scale-down"
  scaling_adjustment      = -1
  adjustment_type         = var.adjustment_type
  cooldown                = var.cooldown
  autoscaling_group_name  = aws_autoscaling_group.app_asg.name
  metric_aggregation_type = var.metric_aggregation_type
}

resource "aws_cloudwatch_metric_alarm" "high_cpu_alarm" {
  alarm_name          = var.high_cpu_alarm_name
  comparison_operator = var.high_cpu_comparison_operator
  evaluation_periods  = var.evaluation_periods
  metric_name         = var.metric_name
  namespace           = var.namespace
  period              = var.period
  statistic           = var.statistic
  threshold           = var.high_cpu_threshold
  alarm_description   = var.alarm_description
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_asg.name
  }
}

resource "aws_cloudwatch_metric_alarm" "low_cpu_alarm" {
  alarm_name          = var.low_cpu_alarm_name
  comparison_operator = var.low_cpu_comparison_operator
  evaluation_periods  = var.evaluation_periods
  metric_name         = var.metric_name
  namespace           = var.namespace
  period              = var.period
  statistic           = var.statistic
  threshold           = var.low_cpu_threshold
  alarm_description   = var.alarm_description
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_asg.name
  }
}

# Define a policy for SNS publish permission to the specific topic
resource "aws_iam_policy" "sns_publish_policy" {
  name        = "SNSPublishPolicy"
  description = "Policy to allow publishing to the SNS topic for user verification."

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "sns:Publish",
        Resource = aws_sns_topic.user_verification.arn
      }
    ]
  })
}

# Attach the SNS publish policy to the existing EC2 IAM role
resource "aws_iam_policy_attachment" "sns_publish_policy_attachment" {
  name       = "sns_publish_policy_attachment"
  roles      = [aws_iam_role.s3_access_role_to_ec2.name]
  policy_arn = aws_iam_policy.sns_publish_policy.arn
}


# IAM Role for Lambda Execution
resource "aws_iam_role" "lambda_exec_role" {
  name = "UserVerificationLambdaExecRole"

  # Allow Lambda to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy to grant permissions to Lambda
resource "aws_iam_policy" "lambda_exec_policy" {
  name        = "UserVerificationLambdaExecPolicy"
  description = "Policy to allow Lambda function to access SNS, RDS, and CloudWatch."

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "sns:Publish",
          "cloudwatch:PutMetricData",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = ["ses:SendEmail", "ses:SendRawEmail"],
        Resource = "*"
      }

    ]
  })
}

# Attach the policy to the Lambda execution role
resource "aws_iam_role_policy_attachment" "lambda_exec_policy_attachment" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_exec_policy.arn
}

resource "aws_sns_topic" "user_verification" {
  name = var.sns_topic_name
}
resource "aws_lambda_function" "user_verification" {
  function_name = var.lambda_function_name
  filename      = var.deployment_package
  handler       = var.handler
  runtime       = var.lambda_runtime
  role          = aws_iam_role.lambda_exec_role.arn
  timeout       = var.timeout

  environment {
    variables = {
      SENDGRID_API_KEY = var.sendgrid_api_key
      DOMAIN           = "${var.env}${var.domain_name}"
    }
  }

  source_code_hash = filebase64sha256(var.deployment_package)
}

# Allow SNS to invoke the Lambda function
resource "aws_lambda_permission" "allow_sns_invoke_lambda" {
  statement_id  = "AllowSNSInvokeLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.user_verification.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.user_verification.arn
}

# Subscribe Lambda function to SNS topic
resource "aws_sns_topic_subscription" "lambda_sns_subscription" {
  topic_arn = aws_sns_topic.user_verification.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.user_verification.arn
}