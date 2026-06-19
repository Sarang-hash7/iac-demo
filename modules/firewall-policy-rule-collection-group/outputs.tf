output "rule_collection_group_id" {

  description = "Firewall Policy Rule Collection Group ID"

  value = azurerm_firewall_policy_rule_collection_group.this.id
}

output "rule_collection_group_name" {

  description = "Firewall Policy Rule Collection Group Name"

  value = azurerm_firewall_policy_rule_collection_group.this.name
}