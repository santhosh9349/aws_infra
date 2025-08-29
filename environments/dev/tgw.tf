module "tgw" {
  source = "../../modules/tgw"

  description = "Transit Gateway for inspection VPC"
  tags        = var.tgw_tags
  vpc_id      = module.vpc["inspection"].vpc_id
  subnet_ids  = [
    module.pub_subnets["inspection_priv_sub1"].subnet_id,
    module.pub_subnets["inspection_priv_sub2"].subnet_id
  ]
  attachment_tags = {
    Name        = "inspection-tgw-attachment"
    Environment = var.environment
  }
  ram_share_name          = "inspection-tgw-share"
  allow_external_principals = false
  ram_tags = {
    Name        = "inspection-tgw-share"
    Environment = var.environment
  }
}

# Additional VPC attachment for prod VPC
resource "aws_ec2_transit_gateway_vpc_attachment" "prod" {
  transit_gateway_id = module.tgw.transit_gateway_id
  vpc_id             = module.vpc["prod"].vpc_id
  subnet_ids         = [
    module.pub_subnets["prod_priv_sub1"].subnet_id,
    module.pub_subnets["prod_priv_sub2"].subnet_id
  ]

  tags = {
    Name        = "prod_tgw_attachment"
    Environment = var.environment
  }
}

# Additional VPC attachment for dev VPC
resource "aws_ec2_transit_gateway_vpc_attachment" "dev" {
  transit_gateway_id = module.tgw.transit_gateway_id
  vpc_id             = module.vpc["dev"].vpc_id
  subnet_ids         = [
    module.pub_subnets["dev_priv_sub1"].subnet_id,
    module.pub_subnets["dev_priv_sub2"].subnet_id
  ]

  tags = {
    Name        = "dev_tgw_attachment"
    Environment = var.environment
  }
}