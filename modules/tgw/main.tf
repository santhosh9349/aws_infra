// filepath: c:\Users\santh\OneDrive\Documents\git\aws_infra\modules\tgw\main.tf
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

resource "aws_ram_resource_share" "this" {
  name                      = var.ram_share_name
  allow_external_principals = var.allow_external_principals

  tags = var.ram_tags
}

resource "aws_ram_resource_association" "this" {
  resource_arn       = aws_ec2_transit_gateway.this.arn
  resource_share_arn = aws_ram_resource_share.this.arn
}