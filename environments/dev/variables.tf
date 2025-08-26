variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-west-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vpcs" {
  description = "Map of VPC names to their CIDR blocks"
  type        = map(string)
  default = {
    "vpc-10"  = "10.0.0.0/16"
    "vpc-172" = "172.0.0.0/16"
    "vpc-192" = "192.0.0.0/16"
  }
}