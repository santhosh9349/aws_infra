output "route_table_id" {
  description = "The ID of the route table"
  value       = aws_route_table.this.id
}

output "route_table_arn" {
  description = "The ARN of the route table"
  value       = aws_route_table.this.arn
}
