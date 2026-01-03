resource "aws_ec2_transit_gateway" "this" {
  description                     = var.description
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
  dns_support                     = "enable"
  vpn_ecmp_support               = "enable"
  
  tags = var.tags
}

# VPC Attachments - one for each VPC
resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  for_each = var.vpc_attachments

  transit_gateway_id = aws_ec2_transit_gateway.this.id
  vpc_id             = each.value.vpc_id
  subnet_ids         = each.value.subnet_ids
  dns_support        = "enable"
  
  transit_gateway_default_route_table_association = true
  transit_gateway_default_route_table_propagation = true

  tags = merge(
    {
      Name = "${each.key}-tgw-attachment"
    },
    each.value.tags
  )
}