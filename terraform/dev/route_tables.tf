# Locals for dynamic route table configuration
locals {
  # Get all VPC names dynamically
  all_vpc_names = keys(var.vpcs)
  
  # Create a map of VPC to its destination CIDRs (all other VPCs)
  vpc_route_destinations = {
    for vpc_name in local.all_vpc_names : vpc_name => [
      for other_vpc_name, cidr in var.vpcs : cidr if other_vpc_name != vpc_name
    ]
  }
  
  # Dynamically group subnets by VPC and type (public/private)
  subnets_by_vpc_and_type = {
    for vpc_name in local.all_vpc_names : vpc_name => {
      public = [
        for subnet_key, subnet_data in local.subnet_map :
        module.subnets[subnet_key].subnet_id
        if subnet_data.vpc_name == vpc_name && startswith(subnet_data.subnet_name, "pub_")
      ]
      private = [
        for subnet_key, subnet_data in local.subnet_map :
        module.subnets[subnet_key].subnet_id
        if subnet_data.vpc_name == vpc_name && startswith(subnet_data.subnet_name, "priv_")
      ]
    }
  }
}

# Internet Gateways for public subnet access - dynamically created for all VPCs
resource "aws_internet_gateway" "igw" {
  for_each = var.vpcs

  vpc_id = module.vpc[each.key].vpc_id

  tags = {
    Name        = "${each.key}-igw"
    Environment = var.environment
    VPC         = each.key
    ManagedBy   = "Terraform"
    Project     = "AWS Infrastructure"
    CostCenter  = var.environment
    Owner       = "DevOps Team"
  }
}

# Private Route Tables - Dynamically created for all VPCs with routes to other VPCs via TGW
module "private_route_tables" {
  source   = "../modules/route_table"
  for_each = {
    for vpc_name in local.all_vpc_names : "${vpc_name}_private" => {
      vpc_name          = vpc_name
      vpc_id            = module.vpc[vpc_name].vpc_id
      subnet_ids        = local.subnets_by_vpc_and_type[vpc_name].private
      destination_cidrs = local.vpc_route_destinations[vpc_name]
    }
    # Only create if there are private subnets
    if length(local.subnets_by_vpc_and_type[vpc_name].private) > 0
  }

  vpc_id                  = each.value.vpc_id
  subnet_ids              = each.value.subnet_ids
  transit_gateway_id      = module.tgw.transit_gateway_id
  destination_cidr_blocks = toset(each.value.destination_cidrs)

  tags = {
    Name        = "${each.value.vpc_name}-private-rt"
    Environment = var.environment
    VPC         = each.value.vpc_name
    Type        = "private"
    ManagedBy   = "Terraform"
    Project     = "AWS Infrastructure"
    CostCenter  = var.environment
    Owner       = "DevOps Team"
  }
}

# Public Route Tables - Dynamically created for all VPCs with IGW and TGW routes
module "public_route_tables" {
  source   = "../modules/route_table"
  for_each = {
    for vpc_name in local.all_vpc_names : "${vpc_name}_public" => {
      vpc_name          = vpc_name
      vpc_id            = module.vpc[vpc_name].vpc_id
      subnet_ids        = local.subnets_by_vpc_and_type[vpc_name].public
      igw_id            = aws_internet_gateway.igw[vpc_name].id
      destination_cidrs = local.vpc_route_destinations[vpc_name]
    }
    # Only create if there are public subnets
    if length(local.subnets_by_vpc_and_type[vpc_name].public) > 0
  }

  vpc_id                  = each.value.vpc_id
  subnet_ids              = each.value.subnet_ids
  transit_gateway_id      = module.tgw.transit_gateway_id
  destination_cidr_blocks = toset(each.value.destination_cidrs)
  internet_gateway_id     = each.value.igw_id

  tags = {
    Name        = "${each.value.vpc_name}-public-rt"
    Environment = var.environment
    VPC         = each.value.vpc_name
    Type        = "public"
    ManagedBy   = "Terraform"
    Project     = "AWS Infrastructure"
    CostCenter  = var.environment
    Owner       = "DevOps Team"
  }
}
