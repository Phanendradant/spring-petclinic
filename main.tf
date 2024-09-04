provider "aws" {
  region = "us-east-1"
}

# VPC
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "MainVPC"
  }
}

# Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "PublicSubnet"
  }
}

# Private Subnet
resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1a"
  tags = {
    Name = "PrivateSubnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = "MainInternetGateway"
  }
}

# Route Table for Public Subnet
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name = "PublicRouteTable"
  }
}

# Associate Public Route Table to Public Subnet
resource "aws_route_table_association" "public_rta" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Security Group allowing HTTP/HTTPS, SSH, and custom port 8080
resource "aws_security_group" "allow_http_https" {
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_http_https_8080"
  }
}

# S3 Bucket
resource "aws_s3_bucket" "my_bucket" {
  bucket = "my-unique-s3-bucket-name-${random_id.bucket_suffix.hex}"  # Ensure uniqueness by appending a random ID

  tags = {
    Name = "MyBucket"
  }
}

# Generate random ID for S3 bucket name suffix
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# S3 Bucket ACL (to replace deprecated acl argument)
resource "aws_s3_bucket_acl" "my_bucket_acl" {
  bucket = aws_s3_bucket.my_bucket.id
  acl    = "private"
}

# IAM Role for EC2 to access S3
resource "aws_iam_role" "ec2_role" {
  name = "ec2_s3_access_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for S3 Access
resource "aws_iam_policy" "s3_access_policy" {
  name = "ec2_s3_access_policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        Effect   = "Allow",
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.my_bucket.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.my_bucket.bucket}/*"
        ]
      }
    ]
  })
}

# Attach the policy to the IAM Role
resource "aws_iam_role_policy_attachment" "ec2_s3_access_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

# IAM Instance Profile for EC2
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2_instance_profile"
  role = aws_iam_role.ec2_role.name
}

# EC2 Instance in the Public Subnet
resource "aws_instance" "web_instance" {
  ami                         = "ami-0e86e20dae9224db8"  # Ensure this AMI is valid in your region
  instance_type               = "t2.medium"
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids       = [aws_security_group.allow_http_https.id]
  key_name                    = "project_key"  # Ensure this key pair exists in your AWS account
  associate_public_ip_address  = true
  iam_instance_profile         = aws_iam_instance_profile.ec2_instance_profile.name

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              EOF

  tags = {
    Name = "WebServerInstance"
  }
}

# Output the instance's public IP
output "instance_public_ip" {
  value = aws_instance.web_instance.public_ip
}
