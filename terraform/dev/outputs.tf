output "vpc_ids" {
  description = "IDs of the created VPCs"
  value       = { for k, v in module.vpc : k => v.vpc_id }
}

output "vpc_cidrs" {
  description = "CIDR blocks of the created VPCs"
  value       = { for k, v in module.vpc : k => v.vpc_cidr_block }
}
