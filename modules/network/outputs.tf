output "vnet_id" {
  value = azurerm_virtual_network.this.id
}

output "subnet_ids" {
  value = {
    for k, v in azurerm_subnet.this :
    k => v.id
  }
}

output "private_endpoint_subnet_id" {
  value = azurerm_subnet.private_endpoints.id
}