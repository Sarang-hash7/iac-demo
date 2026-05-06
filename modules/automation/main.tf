resource "azurerm_automation_account" "this" {
  name                = var.automation_account_name
  location            = var.location
  resource_group_name = var.resource_group
  sku_name            = "Basic"
  identity {
    type = "SystemAssigned"
  }
  tags = var.tags
}

data "azurerm_role_definition" "vm_contrib" {
  name = "Virtual Machine Contributor"
}

resource "azurerm_role_assignment" "automation_vm_contrib" {
  scope              = var.resource_group_id
  role_definition_id = data.azurerm_role_definition.vm_contrib.id
  principal_id       = azurerm_automation_account.this.identity[0].principal_id
  depends_on         = [azurerm_automation_account.this]
}
