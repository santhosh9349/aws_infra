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
}