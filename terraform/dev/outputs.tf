# VPC Outputs - ACTIVE
output "vpc_ids" {
  description = "IDs of the created VPCs"
  value       = { for k, v in module.vpc : k => v.vpc_id }
}

output "vpc_cidrs" {
  description = "CIDR blocks of the created VPCs"
  value       = { for k, v in module.vpc : k => v.vpc_cidr_block }
}

# Internal Web Server Outputs
output "internal_web_server_instance_id" {
  description = "The ID of the internal web server EC2 instance"
  value       = module.internal_web_server.instance_id
}

output "internal_web_server_private_ip" {
  description = "The private IP address of the internal web server"
  value       = module.internal_web_server.private_ip
}

output "internal_web_server_security_group_id" {
  description = "The security group ID for the internal web server"
  value       = module.internal_web_server.security_group_id
}

output "internal_web_server_iam_role_arn" {
  description = "The IAM role ARN for SSM access"
  value       = module.internal_web_server.iam_role_arn
}

/*
COMMENTED OUT - Will be activated after networking is deployed

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
*/
