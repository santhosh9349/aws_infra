terraform {
  cloud {
    organization = "santhosh9349"
    workspaces {
      name = "aws_infra"
    }
  }
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.31.0"
    }
  }
}