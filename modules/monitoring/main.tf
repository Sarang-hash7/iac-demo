resource "azurerm_log_analytics_workspace" "this" {
  name                = var.workspace_name
  location            = var.location
  resource_group_name = var.resource_group
  sku                 = "PerGB2018"
  retention_in_days   = var.retention_in_days
  daily_quota_gb      = var.daily_quota_gb
  tags                = var.tags
}

# Send platform metrics from VMs to Log Analytics via diagnostic settings
resource "azurerm_monitor_diagnostic_setting" "vm_metrics" {
  for_each = var.vm_resource_ids

  name                       = "diag-${each.key}-${substr(var.workspace_name, 0, 12)}"
  target_resource_id         = each.value
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
