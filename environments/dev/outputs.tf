output "vpc_ids" {
  description = "IDs of the created VPCs"
  value       = { for k, v in module.vpc : k => v.vpc_id }
}

output "vpc_cidrs" {
  description = "CIDR blocks of the created VPCs"
  value       = { for k, v in module.vpc : k => v.vpc_cidr_block }
}

output "transit_gateway_id" {
  description = "ID of the Transit Gateway"
  value       = module.tgw.transit_gateway_id
}

output "vpc_attachment_id" {
  description = "ID of the VPC attachment"
  value       = module.tgw.vpc_attachment_id
}

output "ram_resource_share_arn" {
  description = "ARN of the RAM resource share for the TGW"
  value       = module.tgw.ram_resource_share_arn
}

output "prod_tgw_attachment_id" {
  description = "ID of the prod VPC TGW attachment"
  value       = aws_ec2_transit_gateway_vpc_attachment.prod.id
}

output "dev_tgw_attachment_id" {
  description = "ID of the dev VPC TGW attachment"
  value       = aws_ec2_transit_gateway_vpc_attachment.dev.id
}
