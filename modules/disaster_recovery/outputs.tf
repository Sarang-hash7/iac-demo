output "vault_id" {
  value = azurerm_recovery_services_vault.this.id
}

output "vault_name" {
  value = azurerm_recovery_services_vault.this.name
}

output "cache_storage_account_id" {
  value = azurerm_storage_account.asr_cache.id
}