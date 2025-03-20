# Terraform Infrastructure Setup

## Overview
This Terraform script provisions a secure and scalable AWS environment to host a web application. It includes:
- An **EC2 instance** for running the application
- A **Security Group** to control inbound and outbound traffic
- **IAM Roles and Policies** to enforce the principle of least privilege
- **CloudWatch monitoring** to track system health

## Infrastructure Choices

### EC2 Instance Type
- **Instance Type**: `t2.micro`
- **Reason**:
  - Cost-effective for testing and small workloads
  - Provides a good balance of performance and cost
  - Eligible for AWS Free Tier
  
### Additional AWS Resources
- **Security Group**: Controls access to the instance (allows HTTP and SSH traffic)
- **IAM Role & Policy**: Grants EC2 instance access to read from an S3 bucket while following the principle of least privilege
- **CloudWatch Monitoring**: Tracks key system health metrics to ensure reliability

## Scalability and Security
### Scalability
- Terraform allows easy scaling by modifying the `instance_type` or implementing **Auto Scaling Groups** in the future.
- Security groups can be dynamically updated to support load balancing.

### Security
- **IAM Role & Policies** follow the **principle of least privilege** to prevent excessive permissions.
- The **security group** restricts incoming connections to only essential ports (22 and 80).

## Monitoring and CloudWatch Metrics
### Metrics Monitored:
1. **CPU Utilization** (`AWS/EC2 - CPU Utilization`)
   - Ensures the instance is not overloaded
   - Helps decide when to scale up or optimize application performance

2. **Disk Usage** (Custom Metric - `AWS/EC2`)
   - Monitors storage space to prevent application failures due to insufficient disk space

3. **Network Traffic** (`AWS/EC2 - NetworkIn & NetworkOut`)
   - Detects high or unexpected traffic, which could indicate performance issues or security threats

## IAM Roles and Policies
### IAM Role: `ec2_s3_read_role`
- **Purpose**: Grants EC2 instances permission to read from an S3 bucket
- **Why**: The web application might need to fetch static content or configuration files from S3

### IAM Policy: `s3_read_policy`
- **Permissions Granted**:
  - `s3:GetObject`: Allows the EC2 instance to read files from the specified S3 bucket
- **Security Principle**:
  - The instance **cannot** modify or delete S3 data, ensuring security and compliance

## Setup Instructions
### Prerequisites
- Install Terraform (`>=1.0.0`)
- AWS credentials configured (`~/.aws/credentials` or environment variables)

### Deployment Steps
1. **Clone the Repository:**
   ```sh
   git clone https://github.com/YOUR_GITHUB_USERNAME/terraform-aws-setup.git
   cd terraform-aws-setup
   ```
2. **Initialize Terraform:**
   ```sh
   terraform init
   ```
3. **Plan the Infrastructure:**
   ```sh
   terraform plan
   ```
4. **Apply the Configuration:**
   ```sh
   terraform apply -auto-approve
   ```
5. **Retrieve the Public IP:**
   ```sh
   terraform output instance_public_ip
   ```

### Destroying the Infrastructure
To delete all resources created by Terraform, run:
```sh
terraform destroy -auto-approve
```

## Assumptions
- **Region:** The script uses `us-east-1`, but you can modify it in `main.tf`.
- **Security:** The security group allows SSH (22) from anywhere, which should be restricted for production.
- **IAM Role:** The EC2 instance is granted **read-only** S3 access.

## Next Steps
- Implement Auto Scaling for dynamic resource allocation
- Use a Load Balancer for handling high traffic
- Configure AWS Systems Manager for automated maintenance and security patching

---
**Author:** Aiman Fatihah
**Date:** March 21, 2025 
**Company/Project:** Pixlr - DevOps Assessment

