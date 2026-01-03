// Local value for VPC names used in subnet creation
// IMPORTANT: Subnet naming convention is used to determine public IP assignment
// - Subnets with names starting with "pub_" will have map_public_ip_on_launch = true
// - All other subnets (including "priv_" prefix) will have map_public_ip_on_launch = false
// This convention must be maintained in the var.subnets configuration
locals {
  vpc_names = keys(var.subnets)
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

module "subnets" {
  source   = "../modules/subnet"
  for_each = local.subnet_map

  vpc_id            = module.vpc[each.value.vpc_name].vpc_id
  cidr_block        = each.value.cidr
  availability_zone = null
  # Public subnets (prefix "pub_") get public IPs, private subnets do not
  map_public_ip_on_launch = startswith(each.value.subnet_name, "pub_")
  tags = {
    Name        = each.value.subnet_name
    Environment = var.environment
    VPC         = each.value.vpc_name
    Type        = startswith(each.value.subnet_name, "pub_") ? "public" : "private"
  }
}
