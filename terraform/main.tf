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

# IAM Role for EC2 to access ECR and SSM
resource "aws_iam_role" "ec2_role" {
  name = "strapi-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

# Attach SSM access policy
resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach ECR read access policy
resource "aws_iam_role_policy_attachment" "ecr_readonly" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Create Instance Profile for EC2 to assume the Role
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "strapi-ec2-profile-new"
  role = aws_iam_role.ec2_role.name
}

# EC2 Instance for Strapi
resource "aws_instance" "strapi" {
  ami                    = "ami-01621ce8f257d0d13"  # Amazon Linux 2023
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.strapi_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  key_name               = var.key_name

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y docker
    service docker start
    usermod -a -G docker ec2-user
    systemctl enable docker

    # Login to ECR
    aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.eu-west-1.amazonaws.com

    # Pull and run Strapi container
    docker pull ${data.aws_caller_identity.current.account_id}.dkr.ecr.eu-west-1.amazonaws.com/strapi:${var.image_tag}
    docker run -d -p 1337:1337 ${data.aws_caller_identity.current.account_id}.dkr.ecr.eu-west-1.amazonaws.com/strapi:${var.image_tag}
  EOF

  tags = {
    Name = "Strapi-EC2"
  }
}
