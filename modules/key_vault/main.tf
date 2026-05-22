data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  name                      = var.name
  location                  = var.location
  resource_group_name       = var.resource_group
  tenant_id                 = data.azurerm_client_config.current.tenant_id
  sku_name                  = "standard"
  purge_protection_enabled  = false
  enable_rbac_authorization = true
  tags                      = var.tags
}

resource "azurerm_monitor_diagnostic_setting" "key_vault" {
  name                       = "${var.name}-diagnostics"
  target_resource_id         = azurerm_key_vault.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AuditEvent"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

resource "azurerm_role_assignment" "pipeline_kv_secrets_user" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.pipeline_sp_object_id
}

resource "azurerm_role_assignment" "user_kv_admin" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = var.admin_object_id
}