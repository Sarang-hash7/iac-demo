data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  name                     = var.name
  location                 = var.location
  resource_group_name      = var.resource_group
  tenant_id                = data.azurerm_client_config.current.tenant_id
  sku_name                 = "standard"
  purge_protection_enabled = false
  tags                     = var.tags
}
