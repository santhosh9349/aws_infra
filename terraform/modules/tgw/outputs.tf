output "transit_gateway_id" {
  description = "The ID of the Transit Gateway"
  value       = aws_ec2_transit_gateway.this.id
}

output "transit_gateway_arn" {
  description = "The ARN of the Transit Gateway"
  value       = aws_ec2_transit_gateway.this.arn
}

output "vpc_attachment_ids" {
  description = "Map of VPC attachment IDs"
  value       = { for k, v in aws_ec2_transit_gateway_vpc_attachment.this : k => v.id }
}

output "default_route_table_id" {
  description = "The ID of the default Transit Gateway route table"
  value       = aws_ec2_transit_gateway.this.association_default_route_table_id
}