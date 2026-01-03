/*
Route Tables configuration - COMMENTED OUT FOR INITIAL DEPLOYMENT
Uncomment after VPCs and subnets are successfully deployed
*/

/*
# Locals for dynamic route table configuration
locals {
  # Create a map of VPC to its destination CIDRs (all other VPCs)
  vpc_route_destinations = {
    for vpc_name in local.vpc_names : vpc_name => [
      for other_vpc_name, cidr in var.vpcs : cidr if other_vpc_name != vpc_name
    ]
  }
  
  # Dynamically group subnets by VPC and type (public/private) - using KEYS not IDs
  subnets_by_vpc_and_type = {
    for vpc_name in local.vpc_names : vpc_name => {
      public = [
        for subnet_key, subnet_data in local.subnet_map :
        subnet_key
        if subnet_data.vpc_name == vpc_name && startswith(subnet_data.subnet_name, "pub_")
      ]
      private = [
        for subnet_key, subnet_data in local.subnet_map :
        subnet_key
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
    for vpc_name in local.vpc_names : "${vpc_name}_private" => {
      vpc_name          = vpc_name
      vpc_id            = module.vpc[vpc_name].vpc_id
      subnet_keys       = local.subnets_by_vpc_and_type[vpc_name].private
      destination_cidrs = local.vpc_route_destinations[vpc_name]
    }
    # Only create if there are private subnets
    if length(local.subnets_by_vpc_and_type[vpc_name].private) > 0
  }

  vpc_id                  = each.value.vpc_id
  transit_gateway_id      = module.tgw.transit_gateway_id
  destination_cidr_blocks = toset(each.value.destination_cidrs)
  internet_gateway_id     = ""  # Private subnets don't use IGW

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

# Private Subnet Route Table Associations
resource "aws_route_table_association" "private" {
  for_each = merge([
    for vpc_name in local.vpc_names : {
      for subnet_key in local.subnets_by_vpc_and_type[vpc_name].private :
      subnet_key => {
        subnet_id      = module.subnets[subnet_key].subnet_id
        route_table_id = module.private_route_tables["${vpc_name}_private"].route_table_id
      }
    }
    if length(local.subnets_by_vpc_and_type[vpc_name].private) > 0
  ]...)

  subnet_id      = each.value.subnet_id
  route_table_id = each.value.route_table_id
}

# Public Route Tables - Dynamically created for all VPCs with IGW and TGW routes
module "public_route_tables" {
  source   = "../modules/route_table"
  for_each = {
    for vpc_name in local.vpc_names : "${vpc_name}_public" => {
      vpc_name          = vpc_name
      vpc_id            = module.vpc[vpc_name].vpc_id
      subnet_keys       = local.subnets_by_vpc_and_type[vpc_name].public
      igw_id            = aws_internet_gateway.igw[vpc_name].id
      destination_cidrs = local.vpc_route_destinations[vpc_name]
    }
    # Only create if there are public subnets
    if length(local.subnets_by_vpc_and_type[vpc_name].public) > 0
  }

  vpc_id                  = each.value.vpc_id
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

# Public Subnet Route Table Associations
resource "aws_route_table_association" "public" {
  for_each = merge([
    for vpc_name in local.vpc_names : {
      for subnet_key in local.subnets_by_vpc_and_type[vpc_name].public :
      subnet_key => {
        subnet_id      = module.subnets[subnet_key].subnet_id
        route_table_id = module.public_route_tables["${vpc_name}_public"].route_table_id
      }
    }
    if length(local.subnets_by_vpc_and_type[vpc_name].public) > 0
  ]...)

  subnet_id      = each.value.subnet_id
  route_table_id = each.value.route_table_id
}
*/
