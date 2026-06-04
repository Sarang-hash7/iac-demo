locals {
  env   = var.environment
  index = "01"

  names = {
    rg   = "rg-hub-network-centralindia"
    vnet = "vnet-hub-centralindia"
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

  vnet_name     = local.names.vnet
  address_space = var.vnet_cidr
  subnets       = var.subnets

  resource_group = module.resource_group.resource_group_name
  location       = var.location

  private_endpoint_subnet = var.network_private_endpoint_subnet

  subnet_name_overrides = var.subnet_name_overrides

  tags = var.common_tags
}

# ========================
# Private DNS
# ========================

module "private_dns" {
  source = "../../modules/private_dns"

  dns_zone_name       = "privatelink.vaultcore.azure.net"
  resource_group_name = module.resource_group.resource_group_name

  vnet_links = {
    hub = {
      name    = "hub-vnet-link"
      vnet_id = module.network.vnet_id
    }
  }
}