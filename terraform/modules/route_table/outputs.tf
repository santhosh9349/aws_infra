output "route_table_id" {
  description = "The ID of the route table"
  value       = aws_route_table.this.id
}

output "route_table_arn" {
  description = "The ARN of the route table"
  value       = aws_route_table.this.arn
}

output "route_table_association_ids" {
  description = "Map of subnet IDs to route table association IDs"
  value       = { for k, v in aws_route_table_association.this : k => v.id }
}
