module "vpc" {
  source      = "../../../modules/vpc/"
  vpcs        = var.vpcs
  tags_common = var.tags_common
}

module "subnet" {
  source      = "../../../modules/subnet/"
  subnets     = var.subnets
  vpcs        = module.vpc.vpcs
  igws        = module.vpc.igws
  natgw       = local.natgw_routes
  eni         = null
  tgw         = module.transit_gateway.tgw_id
  vpce        = module.vmseries-modules_gwlb_endpoint_set # TODO: this isnt used
  tags_common = var.tags_common
}

locals {
  natgw_routes = {
    for natgw_key, natgw_value in var.nat_gateways : natgw_value.routes_from => aws_nat_gateway.nat_gateways[natgw_key].id
  }
}
