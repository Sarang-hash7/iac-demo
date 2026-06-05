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

# ========================
# Network
# ========================

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