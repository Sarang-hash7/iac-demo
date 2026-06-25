resource "azurerm_recovery_services_vault" "this" {
  name                = var.vault_name
  location            = var.dr_location
  resource_group_name = var.dr_resource_group

  sku = "Standard"

  tags = var.tags
}

resource "azurerm_storage_account" "asr_cache" {
  name                = var.cache_storage_account_name
  resource_group_name = var.primary_resource_group
  location            = var.primary_location

  account_tier             = "Standard"
  account_replication_type = "LRS"

  min_tls_version               = "TLS1_2"
  public_network_access_enabled = true

  tags = var.tags
}

resource "azurerm_site_recovery_replication_policy" "this" {
  name                = var.replication_policy_name
  recovery_vault_name = azurerm_recovery_services_vault.this.name
  resource_group_name = var.dr_resource_group

  recovery_point_retention_in_minutes                  = 1440
  application_consistent_snapshot_frequency_in_minutes = 240
}