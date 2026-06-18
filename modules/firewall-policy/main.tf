resource "azurerm_firewall_policy" "this" {

  name                = var.firewall_policy_name
  location            = var.location
  resource_group_name = var.resource_group_name

  sku = var.firewall_policy_sku

  dns {
    proxy_enabled = var.dns_proxy_enabled
  }

  tags = var.tags
}