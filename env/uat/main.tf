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
  source         = "../../modules/network"
  vnet_name      = local.names.vnet
  address_space  = var.vnet_cidr
  subnets        = var.subnets
  resource_group = module.resource_group.resource_group_name
  location       = var.location
  tags           = var.common_tags
}

# ========================
# Key Vault
# ========================
module "key_vault" {
  source         = "../../modules/key_vault"
  name           = local.names.kv
  location       = var.location
  resource_group = module.resource_group.resource_group_name
  tags           = var.common_tags
}

# ========================
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

