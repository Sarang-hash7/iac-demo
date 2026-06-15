locals {
  ssh_public_key = trimspace(data.azurerm_key_vault_secret.ssh_public_key.value)
  # 🔴 Canonical naming (aligned with LLD)
  env   = var.environment
  index = "01"

  name_prefix = local.env

  # ✅ Central naming map
  names = {
    rg   = "rg-${local.name_prefix}-${local.index}"
    vnet = "vnet-${local.name_prefix}"
    kv   = var.kv_name != null ? var.kv_name : "kv-${local.name_prefix}-${local.index}"
    law  = "log-${local.name_prefix}"
    auto = "auto-${local.name_prefix}"
  }
}

data "azurerm_virtual_network" "agent_vnet" {
  name                = "iac-self-hosted-vnet"
  resource_group_name = "iac-self-hosted_group"
}

data "azurerm_private_dns_zone" "hub_kv" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = "rg-hub-network-centralindia"
}

# ========================
# Resource Group
# ========================
module "resource_group" {
  source   = "../../modules/resource_group"
  name     = local.names.rg
  location = var.location
  tags     = var.common_tags
}

# ========================
# Network
# ========================
module "network" {
  source                  = "../../modules/network"
  vnet_name               = local.names.vnet
  address_space           = var.vnet_cidr
  subnets                 = var.subnets
  resource_group          = module.resource_group.resource_group_name
  location                = var.location
  private_endpoint_subnet = var.network_private_endpoint_subnet
  tags                    = var.common_tags
}

module "vnet_peering" {
  source = "../../modules/vnet_peering"

  vnet_a_name           = module.network.vnet_name
  vnet_a_resource_group = module.resource_group.resource_group_name
  vnet_a_id             = module.network.vnet_id

  vnet_b_name           = data.azurerm_virtual_network.agent_vnet.name
  vnet_b_resource_group = data.azurerm_virtual_network.agent_vnet.resource_group_name
  vnet_b_id             = data.azurerm_virtual_network.agent_vnet.id
}

module "private_dns" {
  source = "../../modules/private_dns"

  dns_zone_name       = "privatelink.vaultcore.azure.net"
  resource_group_name = module.resource_group.resource_group_name

  vnet_links = {
    uat = {
      name    = "uat-vnet-link"
      vnet_id = module.network.vnet_id
    }
  }
}

module "key_vault_private_endpoint" {
  source = "../../modules/private_endpoint"

  name                = "pe-kv-uat"
  location            = var.location
  resource_group_name = module.resource_group.resource_group_name

  subnet_id = module.network.private_endpoint_subnet_id

  private_connection_resource_id = module.key_vault.key_vault_id

  subresource_names = ["vault"]

  private_dns_zone_ids = [
    module.private_dns.dns_zone_id
  ]
}

module "spoke_routes" {
  source = "../../modules/route_table"

  name                = "rt-uat-spoke"
  location            = var.location
  resource_group_name = module.resource_group.resource_group_name

  tags = var.common_tags

  subnet_ids = {
    app = module.network.subnet_ids["app"]
    db  = module.network.subnet_ids["db"]
  }

  routes = {
    prod = {
      address_prefix = "10.20.0.0/16"
      next_hop_type  = "VirtualAppliance"
      next_hop_ip    = "10.0.5.4"
    }
  }
}

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
  tags                       = var.common_tags
}

# =======================
# Read SSH key from Key Vault
# ========================
data "azurerm_key_vault_secret" "ssh_public_key" {
  name         = "vm-ssh-public-key"
  key_vault_id = module.key_vault.key_vault_id

  depends_on = [module.key_vault]
}

# ========================
# Security (NSG)
# ========================
module "security" {
  source         = "../../modules/security"
  resource_group = module.resource_group.resource_group_name
  subnet_map     = module.network.subnet_ids

  nsg_rules = {
    app = var.app_nsg_rules
    db  = var.db_nsg_rules
  }

  location    = var.location
  tags        = var.common_tags
  environment = local.env
}

# ========================
# Compute (VMs)
# ========================
module "compute" {
  source         = "../../modules/compute"
  resource_group = module.resource_group.resource_group_name
  location       = var.location
  vm_config      = var.vm_config
  subnet_map     = module.network.subnet_ids
  nsg_map        = module.security.nsg_ids
  ssh_public_key = trimspace(data.azurerm_key_vault_secret.ssh_public_key.value)

  # 🔴 FIX: pass structured naming instead of raw prefix
  environment    = local.env
  instance_index = local.index

  tags = var.common_tags
}

# ========================
# Monitoring
# ========================
module "monitoring" {
  source            = "../../modules/monitoring"
  resource_group    = module.resource_group.resource_group_name
  location          = var.location
  workspace_name    = local.names.law
  retention_in_days = var.log_analytics_retention_days
  daily_quota_gb    = var.log_analytics_daily_quota_gb
  vm_resource_ids   = module.compute.vm_ids
  tags              = var.common_tags
}

# ========================
# Automation
# ========================
module "automation" {
  source                  = "../../modules/automation"
  resource_group          = module.resource_group.resource_group_name
  resource_group_id       = module.resource_group.resource_group_id
  location                = var.location
  automation_account_name = local.names.auto
  enable_auto_shutdown    = var.enable_auto_shutdown
  vm_resource_ids         = module.compute.vm_ids
  tags                    = var.common_tags
}

module "snapshot_backup" {
  source = "../../modules/snapshot_backup"

  automation_account_name = local.names.auto

  resource_group_name = module.resource_group.resource_group_name
  location            = var.location

  snapshot_target_vm_name        = "vm-uat-db-01"
  snapshot_target_resource_group = module.resource_group.resource_group_name

  snapshot_start_date          = var.snapshot_start_date
  cleanup_start_date           = var.cleanup_start_date
  snapshot_schedule_hour_utc   = 14
  snapshot_schedule_minute_utc = 30

  snapshot_retention_hours = 48

  snapshot_prefix = "uat-db-snapshot"
}

# ========================
# Observability
# ========================

module "observability" {
  source = "../../modules/observability"

  resource_group_name        = module.resource_group.resource_group_name
  location                   = var.location
  log_analytics_workspace_id = module.monitoring.workspace_id

  vms = module.compute.vm_metadata

  environment = local.env
  tags        = var.common_tags
}

# ========================
# Alerting
# ========================

module "alerting" {
  source = "../../modules/alerting"

  resource_group_name = module.resource_group.resource_group_name
  location            = var.location
  environment         = local.env
  tags                = var.common_tags

  action_group_email = var.alert_action_group_email

  log_analytics_workspace_id = module.monitoring.workspace_id
  key_vault_id               = module.key_vault.key_vault_id
  vm_alert_targets           = module.compute.vm_metadata
}
