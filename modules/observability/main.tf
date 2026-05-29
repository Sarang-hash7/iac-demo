resource "azurerm_virtual_machine_extension" "ama" {
  for_each = var.vms

  name               = "AzureMonitorAgent"
  virtual_machine_id = each.value.id
  publisher          = "Microsoft.Azure.Monitor"

  type = (
    each.value.os_type == "windows"
    ? "AzureMonitorWindowsAgent"
    : "AzureMonitorLinuxAgent"
  )

  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true

  tags = var.tags
}