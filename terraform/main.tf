# Define the AWS provider and set the region
# This ensures that all resources are created in the specified AWS region.
provider "aws" {
  region = "us-east-1" 
}

# Define a security group to allow HTTP (80) and SSH (22) access
resource "aws_security_group" "web_sg" {
  name        = "web_sg"
  description = "Allow HTTP and SSH traffic"

  # Allow SSH (port 22) from anywhere - for testing purposes
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Restrict in production
  }

  # Allow HTTP (port 80) to host the web application
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outgoing traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an IAM role for EC2 to follow the principle of least privilege
resource "aws_iam_role" "ec2_role" {
  name = "ec2_s3_read_role"

  assume_role_policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Effect": "Allow",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        }
      }
    ]
  }
  EOF
}

# Attach a policy that allows the EC2 instance to read from a specific S3 bucket
resource "aws_iam_policy" "s3_read_policy" {
  name        = "s3_read_policy"
  description = "Policy to allow EC2 instance to read from S3"

  # pixlr-secure-storage is a bucket name
  policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": ["s3:GetObject"],
        "Resource": "arn:aws:s3:::pixlr-secure-storage/*"
      }
    ]
  }
  EOF
}

# Attach the IAM policy to the role
resource "aws_iam_role_policy_attachment" "s3_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_read_policy.arn
}

# Create an instance profile for the IAM role
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_instance_profile"
  role = aws_iam_role.ec2_role.name
}

# Define an EC2 instance suitable for hosting a web application
resource "aws_instance" "web" {
  ami                    = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2 AMI
  instance_type          = "t2.micro"  # Chosen for cost efficiency and testing purposes
  security_groups        = [aws_security_group.web_sg.name]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name = "WebServer"
  }
}

# Create a CloudWatch alarm to monitor EC2 CPU utilization
resource "aws_cloudwatch_metric_alarm" "cpu_alarm" {
  alarm_name          = "cpu-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace          = "AWS/EC2"
  period             = 60
  statistic          = "Average"
  threshold          = 80
  alarm_description  = "Alarm when CPU usage is too high"
  actions_enabled    = true

  dimensions = {
    InstanceId = aws_instance.web.id
  }
}

# Output the public IP of the instance so users can access the web application
output "instance_public_ip" {
  value = aws_instance.web.public_ip
  description = "Public IP of the web server"
}