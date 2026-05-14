# ========================
# NSG per subnet
# ========================
resource "azurerm_network_security_group" "this" {
  for_each = var.subnet_map

  name                = "nsg-${var.environment}-${each.key}"
  location            = var.location
  resource_group_name = var.resource_group
  tags                = var.tags
}

# ========================
# NSG Rules (applied to each NSG)
# ========================
resource "azurerm_network_security_rule" "this" {
  for_each = merge([
    for subnet_name, rules in var.nsg_rules : {
      for rule in rules :
      "${subnet_name}-${rule.name}" => {
        subnet = subnet_name
        rule   = rule
      }
    }
  ]...)

  name                        = each.value.rule.name
  priority                    = each.value.rule.priority
  direction                   = each.value.rule.direction
  access                      = each.value.rule.access
  protocol                    = each.value.rule.protocol
  resource_group_name         = var.resource_group
  network_security_group_name = azurerm_network_security_group.this[each.value.subnet].name

  # Source port
  source_port_range = "*"

  # Source address — singular if "*", plural if list
  source_address_prefix = (
    length(each.value.rule.source_prefixes) == 1 &&
    contains(
      ["*", "Internet", "VirtualNetwork", "AzureLoadBalancer"],
      each.value.rule.source_prefixes[0]
    )
  ) ? each.value.rule.source_prefixes[0] : null

  source_address_prefixes = (
    length(each.value.rule.source_prefixes) == 1 &&
    contains(
      ["*", "Internet", "VirtualNetwork", "AzureLoadBalancer"],
      each.value.rule.source_prefixes[0]
    )
  ) ? null : each.value.rule.source_prefixes

  # Destination address — singular wildcard (use var if you need flexibility later)
  destination_address_prefix = "*" # ← added

  # Destination port — singular or plural depending on rule definition
  destination_port_range  = each.value.rule.destination_port_range != null ? each.value.rule.destination_port_range : null
  destination_port_ranges = each.value.rule.destination_port_ranges != null ? each.value.rule.destination_port_ranges : null
}

# ========================
# NSG Association to Subnets
# ========================
resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = var.subnet_map

  subnet_id                 = each.value
  network_security_group_id = azurerm_network_security_group.this[each.key].id
}