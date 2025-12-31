# Route Table Resource
resource "aws_route_table" "this" {
  vpc_id = var.vpc_id

  tags = var.tags
}

# Route Table Association with Subnets
resource "aws_route_table_association" "this" {
  for_each = toset(var.subnet_ids)

  subnet_id      = each.value
  route_table_id = aws_route_table.this.id
}

# Routes to other VPCs via Transit Gateway
resource "aws_route" "tgw_routes" {
  for_each = var.destination_cidr_blocks

  route_table_id         = aws_route_table.this.id
  destination_cidr_block = each.value
  transit_gateway_id     = var.transit_gateway_id
}

# Internet Gateway Route (for public subnets)
resource "aws_route" "igw_route" {
  count = var.internet_gateway_id != null ? 1 : 0

  route_table_id         = aws_route_table.this.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = var.internet_gateway_id
}
