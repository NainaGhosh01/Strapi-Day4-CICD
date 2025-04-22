provider "aws" {
  region = var.aws_region
}

# Fetch default VPC
data "aws_vpc" "default" {
  default = true
}

# Fetch subnets in the default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Fetch AWS account ID
data "aws_caller_identity" "current" {}

# Create Security Group for Strapi
resource "aws_security_group" "strapi_sg" {
  name   = "strapi-sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 1337
    to_port     = 1337
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

# EC2 Instance for Strapi
resource "aws_instance" "strapi" {
  ami                    = "ami-01621ce8f257d0d13"  # Amazon Linux 2023
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.strapi_sg.id]
  key_name               = var.key_name

  user_data = <<-EOF
  #!/bin/bash
  yum update -y
  yum install -y docker unzip curl

  systemctl start docker
  systemctl enable docker
  usermod -aG docker ec2-user

  # Install AWS CLI v2
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip
  ./aws/install

  # Configure AWS CLI using your access key (TEMPORARY - not ideal for prod)
  aws configure set aws_access_key_id ${var.aws_access_key_id}
  aws configure set aws_secret_access_key ${var.aws_secret_access_key}
  aws configure set region ${var.aws_region}

  # Login to ECR and pull the image
  aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com
  docker pull ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/strapi:${var.image_tag}

  # Run the Strapi container
  docker run -d -p 1337:1337 ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/strapi:${var.image_tag}
EOF


  tags = {
    Name = "Strapi-EC2"
  }
}
