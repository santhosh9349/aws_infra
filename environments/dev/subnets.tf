// Local value for VPC names used in subnet creation
locals {
  vpc_names  = keys(var.subnets)
  subnet_map = merge([
    for vpc_name in local.vpc_names : {
      for subnet_name, cidr in var.subnets[vpc_name] :
      "${vpc_name}_${subnet_name}" => {
        vpc_name    = vpc_name
        subnet_name = subnet_name
        cidr        = cidr
      }
    }
  ]...)
}

module "pub_subnets" {
  source   = "../../modules/subnet"
  for_each = local.subnet_map

  vpc_id                  = module.vpc[each.value.vpc_name].vpc_id
  cidr_block              = each.value.cidr
  availability_zone       = null
  map_public_ip_on_launch = true
  tags = {
    Name        = each.value.subnet_name
    Environment = var.environment
    VPC         = each.value.vpc_name
  }
}
    Environment = var.environment
    VPC         = each.value.vpc_name
  }
}
