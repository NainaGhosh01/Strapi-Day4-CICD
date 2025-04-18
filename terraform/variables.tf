variable "aws_region" {
  default = "us-east-1"
}

variable "image_tag" {
  description = "Docker image tag for the Strapi app"
  type        = string
}

variable "instance_type" {
  default = "t2.medium"
}

variable "key_name" {
  description = "SSH Key pair name"
  type        = string
}

variable "vpc_id" {}
variable "subnet_id" {}
