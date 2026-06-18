output "firewall_policy_id" {
  description = "Azure Firewall Policy ID"
  value       = azurerm_firewall_policy.this.id
}

output "firewall_policy_name" {
  description = "Azure Firewall Policy Name"
  value       = azurerm_firewall_policy.this.name
}