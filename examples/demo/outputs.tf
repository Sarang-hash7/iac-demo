output "resource_group_name" {
  description = "Name of the created resource group."
  value       = azurerm_resource_group.rg.name
}

output "vm_name" {
  description = "Name of the deployed VM."
  value       = azurerm_linux_virtual_machine.vm.name
}

output "public_ip" {
  description = "Public IP address assigned to the VM."
  value       = azurerm_public_ip.public_ip.ip_address
}
