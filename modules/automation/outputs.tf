output "automation_account_id" {
  value = azurerm_automation_account.this.id
}

output "automation_principal_id" {
  value = azurerm_automation_account.this.identity[0].principal_id
}
