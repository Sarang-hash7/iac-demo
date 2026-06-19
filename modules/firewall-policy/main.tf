resource "azurerm_firewall_policy" "this" {

  name                = var.firewall_policy_name
  location            = var.location
  resource_group_name = var.resource_group_name

  sku = var.firewall_policy_sku

  dynamic "dns" {
    for_each = var.enable_dns_proxy ? [1] : []

    content {
      proxy_enabled = true
    }
  }

  tags = var.tags
}