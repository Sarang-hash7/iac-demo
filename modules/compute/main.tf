locals {
  vm_map = var.vm_config
}

# ========================
# Public IPs
# ========================
resource "azurerm_public_ip" "this" {
  for_each = {
    for k, v in var.vm_config : k => v if v.public_ip
  }

  name                = "pip-${var.environment}-${each.key}-${var.instance_index}"
  location            = var.location
  resource_group_name = var.resource_group
  allocation_method   = "Static"
  sku                 = var.public_ip_sku
  tags                = var.tags
}

# ========================
# NICs
# ========================
resource "azurerm_network_interface" "this" {
  for_each = var.vm_config

  name                 = "nic-${var.environment}-${each.key}-${var.instance_index}"
  location             = var.location
  resource_group_name  = var.resource_group
  ip_forwarding_enabled = each.value.ip_forwarding
  tags                 = var.tags

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.subnet_map[each.value.subnet]
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = lookup(azurerm_public_ip.this, each.key, null) != null ? azurerm_public_ip.this[each.key].id : null
  }
}

# ========================
# VMs
# ========================
resource "azurerm_linux_virtual_machine" "this" {
  for_each = var.vm_config

  name                  = "vm-${var.environment}-${each.key}-${var.instance_index}"
  resource_group_name   = var.resource_group
  location              = var.location
  size                  = each.value.vm_size
  admin_username        = each.value.admin_username
  network_interface_ids = [azurerm_network_interface.this[each.key].id]
  tags                  = var.tags

  identity {
    type = "SystemAssigned"
  }

  admin_ssh_key {
    username   = each.value.admin_username
    public_key = var.ssh_public_key
  }

  lifecycle {
    ignore_changes = [
      admin_ssh_key # prevents VM recreation when ssh key source changes
    ]
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = each.value.os_disk_type
    disk_size_gb         = each.value.os_disk_size_gb
  }

  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }

  custom_data = null

  timeouts {
    create = "60m"
    update = "30m"
    delete = "60m"
  }
}
