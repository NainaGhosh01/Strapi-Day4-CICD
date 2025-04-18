#!/bin/bash
yum update -y
yum install -y docker
service docker start
usermod -a -G docker ec2-user
systemctl enable docker

# Login to ECR (replace with your region and AWS account ID in Terraform for dynamic)
aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin ${aws_account_id}.dkr.ecr.eu-west-1.amazonaws.com

# Pull and run your Strapi container
docker pull ${aws_account_id}.dkr.ecr.eu-west-1.amazonaws.com/strapi:${image_tag}
docker run -d -p 1337:1337 ${aws_account_id}.dkr.ecr.eu-west-1.amazonaws.com/strapi:${image_tag}
