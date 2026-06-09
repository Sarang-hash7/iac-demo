data "azurerm_virtual_network" "uat" {
  name                = "vnet-uat"
  resource_group_name = "rg-uat-01"
}

data "azurerm_virtual_network" "prod" {
  name                = "vnet-prod"
  resource_group_name = "rg-prod-01"
}

data "azurerm_virtual_network" "agent" {
  name                = "iac-self-hosted-vnet"
  resource_group_name = "iac-self-hosted_group"
}

data "azurerm_key_vault" "uat" {
  name                = "kv-uat-56712"
  resource_group_name = "rg-uat-01"
}

data "azurerm_key_vault_secret" "ssh_public_key" {
  name         = "vm-ssh-public-key"
  key_vault_id = data.azurerm_key_vault.uat.id
}

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


module "compute" {
  source = "../../modules/compute"

  environment    = var.environment
  instance_index = "01"

  resource_group = module.resource_group.resource_group_name
  location       = var.location

  vm_config = var.vm_config

  subnet_map = module.network.subnet_ids

  ssh_public_key = trimspace(
    data.azurerm_key_vault_secret.ssh_public_key.value
  )

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

    prod = {
      name    = "prod-vnet-link"
      vnet_id = data.azurerm_virtual_network.prod.id
    }
  }
}

module "hub_to_uat_peering" {
  source = "../../modules/vnet_peering"

  vnet_a_name           = module.network.vnet_name
  vnet_a_resource_group = module.resource_group.resource_group_name
  vnet_a_id             = module.network.vnet_id

  vnet_b_name           = data.azurerm_virtual_network.uat.name
  vnet_b_resource_group = data.azurerm_virtual_network.uat.resource_group_name
  vnet_b_id             = data.azurerm_virtual_network.uat.id
}

module "hub_to_prod_peering" {
  source = "../../modules/vnet_peering"

  vnet_a_name           = module.network.vnet_name
  vnet_a_resource_group = module.resource_group.resource_group_name
  vnet_a_id             = module.network.vnet_id

  vnet_b_name           = data.azurerm_virtual_network.prod.name
  vnet_b_resource_group = data.azurerm_virtual_network.prod.resource_group_name
  vnet_b_id             = data.azurerm_virtual_network.prod.id
}

module "hub_to_agent_peering" {
  source = "../../modules/vnet_peering"

  vnet_a_name           = module.network.vnet_name
  vnet_a_resource_group = module.resource_group.resource_group_name
  vnet_a_id             = module.network.vnet_id

  vnet_b_name           = data.azurerm_virtual_network.agent.name
  vnet_b_resource_group = data.azurerm_virtual_network.agent.resource_group_name
  vnet_b_id             = data.azurerm_virtual_network.agent.id
}