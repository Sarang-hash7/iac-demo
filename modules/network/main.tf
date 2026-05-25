# ========================
# Virtual Network
# ========================
resource "azurerm_virtual_network" "this" {
  name                = var.vnet_name
  address_space       = [var.address_space]
  location            = var.location
  resource_group_name = var.resource_group
  tags                = var.tags
}

# ========================
# Subnets (LLD-aligned)
# ========================
resource "azurerm_subnet" "this" {
  for_each = var.subnets

  # 🔴 FIX: enforce naming convention
  name                 = "snet-${each.key}"
  resource_group_name  = var.resource_group
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [each.value]

  # ✅ Optional: future-ready (safe defaults)
  service_endpoints = var.enable_service_endpoints ? ["Microsoft.Storage"] : []

  dynamic "delegation" {
    for_each = lookup(var.subnet_delegations, each.key, null) != null ? [1] : []
    content {
      name = "delegation"

      service_delegation {
        name = var.subnet_delegations[each.key]
        actions = [
          "Microsoft.Network/virtualNetworks/subnets/action"
        ]
      }
    }
  }
}

resource "azurerm_subnet" "private_endpoints" {
  name                              = var.private_endpoint_subnet.name
  resource_group_name               = var.resource_group
  virtual_network_name              = azurerm_virtual_network.this.name
  address_prefixes                  = [var.private_endpoint_subnet.address_prefix]
  private_endpoint_network_policies = var.private_endpoint_subnet.private_endpoint_network_policies
}