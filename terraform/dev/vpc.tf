module "vpc" {
  source      = "../../modules/vpc"
  for_each    = var.vpcs

  cidr_block           = each.value
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name        = each.key
    Environment = var.environment
  }
}
