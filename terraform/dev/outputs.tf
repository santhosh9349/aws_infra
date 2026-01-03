# VPC Outputs - ACTIVE
output "vpc_ids" {
  description = "IDs of the created VPCs"
  value       = { for k, v in module.vpc : k => v.vpc_id }
}

output "vpc_cidrs" {
  description = "CIDR blocks of the created VPCs"
  value       = { for k, v in module.vpc : k => v.vpc_cidr_block }
}

# /*
# COMMENTED OUT - Will be activated after networking is deployed

# Transit Gateway Outputs
output "transit_gateway_id" {
  description = "The ID of the Transit Gateway"
  value       = module.tgw.transit_gateway_id
}

output "transit_gateway_arn" {
  description = "The ARN of the Transit Gateway"
  value       = module.tgw.transit_gateway_arn
}

output "tgw_vpc_attachment_ids" {
  description = "Map of VPC names to their Transit Gateway attachment IDs"
  value       = module.tgw.vpc_attachment_ids
}

output "tgw_default_route_table_id" {
  description = "The ID of the Transit Gateway default route table"
  value       = module.tgw.default_route_table_id
}

# Route Table Outputs
output "private_route_table_ids" {
  description = "Map of private route table IDs"
  value       = { for k, v in module.private_route_tables : k => v.route_table_id }
}

output "public_route_table_ids" {
  description = "Map of public route table IDs"
  value       = { for k, v in module.public_route_tables : k => v.route_table_id }
}

# Internet Gateway Outputs
output "internet_gateway_ids" {
  description = "Map of Internet Gateway IDs"
  value       = { for k, v in aws_internet_gateway.igw : k => v.id }
}
# */
