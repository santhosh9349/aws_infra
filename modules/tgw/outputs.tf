// filepath: c:\Users\santh\OneDrive\Documents\git\aws_infra\modules\tgw\outputs.tf
output "transit_gateway_id" {
  description = "The ID of the Transit Gateway"
  value       = aws_ec2_transit_gateway.this.id
}

output "transit_gateway_arn" {
  description = "The ARN of the Transit Gateway"
  value       = aws_ec2_transit_gateway.this.arn
}

output "vpc_attachment_id" {
  description = "The ID of the VPC attachment"
  value       = aws_ec2_transit_gateway_vpc_attachment.this.id
}

output "ram_resource_share_arn" {
  description = "ARN of the RAM resource share"
  value       = aws_ram_resource_share.this.arn
}