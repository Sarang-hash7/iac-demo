output "vm_ids" {
  value = { for k, v in azurerm_linux_virtual_machine.this : k => v.id }
}

output "vm_metadata" {
  value = {
    for k, v in azurerm_linux_virtual_machine.this :
    k => {
      id      = v.id
      name    = v.name
      os_type = "linux"
    }
  }
}

output "app_public_ip" {
  value = try(azurerm_public_ip.this["app"].ip_address, "")
}

output "db_private_ip" {
  # NIC private IP is available via the ip_configuration block
  value = try(azurerm_network_interface.this["db"].ip_configuration[0].private_ip_address, "")
}
