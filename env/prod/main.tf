locals {
  env   = var.environment
  index = "01"

  name_prefix = local.env

  names = {
    rg   = "rg-${local.name_prefix}-${local.index}"
    vnet = "vnet-${local.name_prefix}"
  }
}

# ========================
# Resource Group
# ========================

module "resource_group" {
  source = "../../modules/resource_group"

  name     = local.names.rg
  location = var.location
  tags     = var.common_tags
}

# =======================
# Network
# =======================

module "network" {
  source = "../../modules/network"

  vnet_name               = local.names.vnet
  address_space           = var.vnet_cidr
  subnets                 = var.subnets
  resource_group          = module.resource_group.resource_group_name
  location                = var.location
  private_endpoint_subnet = var.network_private_endpoint_subnet

  tags = var.common_tags
}

module "spoke_routes" {
  source = "../../modules/route_table"

  name                = "rt-prod-spoke"
  location            = var.location
  resource_group_name = module.resource_group.resource_group_name

  tags = var.common_tags

  subnet_ids = {
    app = module.network.subnet_ids["app"]
    db  = module.network.subnet_ids["db"]
  }

  routes = {
    uat = {
      address_prefix = "10.10.0.0/16"
      next_hop_type  = "VirtualAppliance"
      next_hop_ip    = "10.0.5.4"
    }
  }
}