variable "aws_region" {
  default = "eu-west-1"
}
variable "aws_access_key_id" {}
variable "aws_secret_access_key" {}

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
