output "firewall_id" {
  description = "Azure Firewall ID"
  value       = azurerm_firewall.this.id
}

output "firewall_name" {
  description = "Azure Firewall Name"
  value       = azurerm_firewall.this.name
}

output "firewall_private_ip" {
  description = "Firewall Private IP Address"
  value       = azurerm_firewall.this.ip_configuration[0].private_ip_address
}

output "firewall_public_ip" {
  description = "Firewall Public IP Address"
  value       = azurerm_public_ip.this.ip_address
}

output "firewall_public_ip_id" {
  description = "Firewall Public IP Resource ID"
  value       = azurerm_public_ip.this.id
}