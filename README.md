# tf-aws-infra


# AWS Networking Infrastructure with Terraform

This repository contains the Terraform templates to set up networking resources in AWS, such as a Virtual Private Cloud (VPC), subnets, Internet Gateway, and Route Tables. The setup ensures proper networking for web applications, making it easy to manage infrastructure as code.

## Prerequisites

Before setting up your AWS networking infrastructure, ensure you have the following tools installed:

1. **Terraform**  
   Install Terraform

2. **AWS CLI**  
   Install and configure the AWS CLI 

   ```bash
   aws configure
   ```

   This command will prompt you for your AWS access key, secret key, region, and output format.

## Setup Instructions

### Step 1: Clone the Repository

Start by cloning this repository:

### Step 2: Configure Terraform Variables

In the `terraform.tfvars` file, you can define specific values for the variables used in your Terraform templates. Modify it as per your needs. Here's an example:

```hcl
aws_region         = "us-east-1"
vpc_cidr           = "10.0.0.0/16"
public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_subnet_cidrs = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
```

### Step 3: Initialize Terraform

Before you can run Terraform commands, you need to initialize your workspace. This downloads the necessary provider plugins and sets up your working directory:

```bash
terraform init
```

### Step 4: Review the Plan

After initialization, you can review what resources will be created without actually applying them by running:

```bash
terraform plan
```

This will provide a detailed description of the resources Terraform will create in your AWS account.

### Step 5: Apply the Configuration

Once you're satisfied with the plan, apply the configuration to create the AWS networking infrastructure:

```bash
terraform apply
```

You'll be prompted to confirm the action by typing `yes`. Terraform will then proceed to create the resources defined in the configuration.

### Step 6: Verify the Infrastructure

After the `terraform apply` process completes, you can verify the created resources by checking the outputs, or you can log into the AWS Console to view the VPC, subnets, internet gateway, and route tables.

### Step 7: Clean Up Resources

If you wish to tear down and remove all the resources created by Terraform, you can run the following command:

```bash
terraform destroy
```

## License

This repository is licensed under the MIT License. See the `LICENSE` file for more details.

# README.MD updated