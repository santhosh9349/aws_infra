/*
Transit Gateway configuration - COMMENTED OUT FOR INITIAL DEPLOYMENT
Uncomment after VPCs and subnets are successfully deployed
*/

/*
# Locals for dynamic TGW attachment configuration
locals {
  # Dynamically create TGW attachments for all VPCs using their private subnets
  tgw_attachments = {
    for vpc_name in local.vpc_names : vpc_name => {
      vpc_id = module.vpc[vpc_name].vpc_id
      subnet_ids = [
        for subnet_key, subnet_data in local.subnet_map :
        module.subnets[subnet_key].subnet_id
        if subnet_data.vpc_name == vpc_name && startswith(subnet_data.subnet_name, "priv_")
      ]
      tags = {
        Environment = var.environment
        VPC         = vpc_name
      }
    }
    # Only create attachment if VPC has private subnets
    if length([
      for subnet_key, subnet_data in local.subnet_map :
      subnet_key if subnet_data.vpc_name == vpc_name && startswith(subnet_data.subnet_name, "priv_")
    ]) > 0
  }
}

module "tgw" {
  source = "../modules/tgw"

  description     = "Transit Gateway for multi-VPC connectivity - Dynamically scales with VPC count"
  tags            = var.tgw_tags
  vpc_attachments = local.tgw_attachments
}
*/