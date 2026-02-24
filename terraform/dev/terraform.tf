terraform {
  cloud {
    organization = "santhosh9349"
    workspaces {
      name = "tf_dev"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.31.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}