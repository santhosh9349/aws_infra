variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
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
    "prod"  = "10.0.0.0/16"
    "dev" = "172.0.0.0/16"
    "inspection" = "192.0.0.0/16"
  }
}