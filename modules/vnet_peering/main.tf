resource "azurerm_virtual_network_peering" "a_to_b" {
  name                      = "${var.vnet_a_name}-to-${var.vnet_b_name}"
  resource_group_name       = var.vnet_a_resource_group
  virtual_network_name      = var.vnet_a_name
  remote_virtual_network_id = var.vnet_b_id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "b_to_a" {
  name                      = "${var.vnet_b_name}-to-${var.vnet_a_name}"
  resource_group_name       = var.vnet_b_resource_group
  virtual_network_name      = var.vnet_b_name
  remote_virtual_network_id = var.vnet_a_id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}