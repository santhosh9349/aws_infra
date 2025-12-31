resource "aws_ec2_transit_gateway" "this" {
  description = var.description
  tags        = var.tags
}

resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  transit_gateway_id = aws_ec2_transit_gateway.this.id
  vpc_id             = var.vpc_id
  subnet_ids         = var.subnet_ids

  tags = var.attachment_tags
}