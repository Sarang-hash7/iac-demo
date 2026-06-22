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

resource "azurerm_network_security_group" "nva" {
  name                = "nsg-hub-nva"
  location            = var.location
  resource_group_name = module.resource_group.resource_group_name

  tags = var.common_tags
}

resource "azurerm_network_security_rule" "nva" {
  for_each = {
    for rule in var.nva_nsg_rules : rule.name => rule
  }

  name                       = each.value.name
  priority                   = each.value.priority
  direction                  = each.value.direction
  access                     = each.value.access
  protocol                   = each.value.protocol
  source_port_range          = each.value.source_port_range
  destination_port_range     = each.value.destination_port_range
  source_address_prefix      = each.value.source_address_prefix
  destination_address_prefix = each.value.destination_address_prefix

  resource_group_name         = module.resource_group.resource_group_name
  network_security_group_name = azurerm_network_security_group.nva.name
}

resource "azurerm_subnet_network_security_group_association" "transit" {
  subnet_id                 = module.network.subnet_ids["transit"]
  network_security_group_id = azurerm_network_security_group.nva.id
}

module "hub_firewall_policy" {
  source = "../../modules/firewall-policy"

  firewall_policy_name = "fwpol-hub-prod"

  location            = var.location
  resource_group_name = module.resource_group.resource_group_name

  firewall_policy_sku = "Basic"

  enable_dns_proxy = false

  tags = var.common_tags
}

##########################################
# Firewall Policy Rule Collection Group
##########################################

module "hub_firewall_policy_rcg" {

  source = "../../modules/firewall-policy-rule-collection-group"

  firewall_policy_id = module.hub_firewall_policy.firewall_policy_id

  rule_collection_group_name = "rcg-hub-default"

  priority = 100

  ##################################################
  # Network Rule Collections
  ##################################################

  network_rule_collections = [

    {
      name     = "allow-infrastructure"
      priority = 100
      action   = "Allow"

      rules = [

        ##################################################
        # DNS
        ##################################################

        {
          name = "allow-dns"

          protocols = [
            "TCP",
            "UDP"
          ]

          source_addresses = [
            "10.10.0.0/16",
            "10.20.0.0/16"
          ]

          destination_addresses = [
            "*"
          ]

          destination_ports = [
            "53"
          ]
        },

        ##################################################
        # HTTP
        ##################################################

        {
          name = "allow-http"

          protocols = [
            "TCP"
          ]

          source_addresses = [
            "10.10.0.0/16",
            "10.20.0.0/16"
          ]

          destination_addresses = [
            "*"
          ]

          destination_ports = [
            "80"
          ]
        },

        ##################################################
        # HTTPS
        ##################################################

        {
          name = "allow-https"

          protocols = [
            "TCP"
          ]

          source_addresses = [
            "10.10.0.0/16",
            "10.20.0.0/16"
          ]

          destination_addresses = [
            "*"
          ]

          destination_ports = [
            "443"
          ]
        }

      ]
    }

  ]

  application_rule_collections = []

  nat_rule_collections = []

}

module "hub_firewall" {
  source = "../../modules/firewall"

  firewall_name = "afw-hub-prod"

  location            = var.location
  resource_group_name = module.resource_group.resource_group_name

  firewall_sku_name = "AZFW_VNet"
  firewall_sku_tier = "Basic"

  firewall_policy_id = module.hub_firewall_policy.firewall_policy_id

  firewall_subnet_id            = module.network.subnet_ids["firewall"]
  firewall_management_subnet_id = module.network.subnet_ids["firewallmanagement"]

  tags = var.common_tags

  depends_on = [
    module.network,
    module.hub_firewall_policy
  ]
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
    uat = {
      name    = "uat-vnet-link"
      vnet_id = data.azurerm_virtual_network.uat.id
    }

    prod = {
      name    = "prod-vnet-link"
      vnet_id = data.azurerm_virtual_network.prod.id
    }
    agent = {
      name    = "agent-vnet-link"
      vnet_id = data.azurerm_virtual_network.agent.id
    }
  }
}

module "postgres_private_dns" {
  source = "../../modules/private_dns"

  dns_zone_name       = "privatelink.postgres.database.azure.com"
  resource_group_name = module.resource_group.resource_group_name

  vnet_links = {
    hub = {
      name    = "hub-postgres-link"
      vnet_id = module.network.vnet_id
    }

    prod = {
      name    = "prod-postgres-link"
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