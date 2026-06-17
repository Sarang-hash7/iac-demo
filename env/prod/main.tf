locals {
  env   = var.environment
  index = "01"

  name_prefix = local.env

  names = {
    rg   = "rg-${local.name_prefix}-${local.index}"
    vnet = "vnet-${local.name_prefix}"
    kv   = var.kv_name != null ? var.kv_name : "kv-${local.name_prefix}-${local.index}"
    law  = "log-${local.name_prefix}"
  }
}

data "azurerm_private_dns_zone" "hub_dns_zone" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = "rg-hub-network-centralindia"
}

data "azurerm_private_dns_zone" "postgres" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = "rg-hub-network-centralindia"
}

data "azurerm_key_vault" "prod" {
  name                = "kv-prod-56712"
  resource_group_name = "rg-prod-01"
}

data "azurerm_key_vault_secret" "postgres_password" {
  name         = "postgres-admin-password"
  key_vault_id = data.azurerm_key_vault.prod.id
}

# =========================
# UAT Key Vault
# =========================

data "azurerm_key_vault" "uat" {
  name                = "kv-uat-56712"
  resource_group_name = "rg-uat-01"
}

data "azurerm_key_vault_secret" "ssh_public_key" {
  name         = "vm-ssh-public-key"
  key_vault_id = data.azurerm_key_vault.uat.id
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

  subnet_delegations = var.subnet_delegations

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
    agent = {
      address_prefix = "10.2.0.0/16"
      next_hop_type  = "VirtualAppliance"
      next_hop_ip    = "10.0.5.4"
    }
  }
}

module "security" {
  source = "../../modules/security"

  environment    = var.environment
  resource_group = module.resource_group.resource_group_name
  location       = var.location

  subnet_map = {
    app = module.network.subnet_ids["app"]
  }

  nsg_rules = {
    app = var.app_nsg_rules
  }

  tags = var.common_tags
}

# ========================
# Key Vault
# ========================

# ========================
# Key Vault
# ========================
module "key_vault" {
  source         = "../../modules/key_vault"
  name           = local.names.kv
  location       = var.location
  resource_group = module.resource_group.resource_group_name

  network_acls = {
    default_action = "Deny"
    bypass         = "None"

    ip_rules = [
      "103.241.182.128/32"
    ]
  }

  log_analytics_workspace_id = module.monitoring.workspace_id
  admin_object_id            = "5f4180f8-0b91-46d0-a76b-9dceef1de46f"
  pipeline_sp_object_id      = "cd648a5e-4c69-4d62-97e5-279b108c88e6"

  tags = var.common_tags
}

module "key_vault_private_endpoint" {
  source = "../../modules/private_endpoint"

  name                = "pe-kv-prod"
  location            = var.location
  resource_group_name = module.resource_group.resource_group_name

  subnet_id = module.network.private_endpoint_subnet_id

  private_connection_resource_id = module.key_vault.key_vault_id

  subresource_names = ["vault"]

  private_dns_zone_ids = [
    data.azurerm_private_dns_zone.hub_dns_zone.id
  ]
}

# ========================
# Compute
# ========================

module "compute" {
  source = "../../modules/compute"

  environment    = var.environment
  instance_index = local.index

  resource_group = module.resource_group.resource_group_name
  location       = var.location

  vm_config = var.vm_config

  subnet_map = {
    app = module.network.subnet_ids["app"]
  }

  ssh_public_key = data.azurerm_key_vault_secret.ssh_public_key.value

  tags = var.common_tags
}

resource "azurerm_postgresql_flexible_server" "prod" {
  name                = "psql-prod-01"
  resource_group_name = module.resource_group.resource_group_name
  location            = var.location

  version                       = "16"
  public_network_access_enabled = false

  delegated_subnet_id = module.network.subnet_ids["postgres"]

  private_dns_zone_id = data.azurerm_private_dns_zone.postgres.id

  administrator_login    = "pgadmin"
  administrator_password = data.azurerm_key_vault_secret.postgres_password.value

  storage_mb = 32768

  sku_name = "B_Standard_B1ms"

  backup_retention_days = 7

  geo_redundant_backup_enabled = false

  zone = "1"

  tags = var.common_tags

  depends_on = [
    module.network
  ]
}

resource "azurerm_postgresql_flexible_server_database" "appdb" {
  name      = "appdb"
  server_id = azurerm_postgresql_flexible_server.prod.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

# ========================
# Monitoring
# ========================

module "monitoring" {
  source = "../../modules/monitoring"

  workspace_name = local.names.law
  location       = var.location
  resource_group = module.resource_group.resource_group_name

  retention_in_days = 30
  daily_quota_gb    = 0.4

  vm_resource_ids = module.compute.vm_ids
  tags            = var.common_tags
}