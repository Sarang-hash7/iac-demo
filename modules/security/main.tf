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
  for_each = {
    for pair in setproduct(keys(var.subnet_map), var.nsg_rules) :
    "${pair[0]}-${pair[1].name}" => {
      subnet = pair[0]
      rule   = pair[1]
    }
  }

  name                = each.value.rule.name
  priority            = each.value.rule.priority
  direction           = each.value.rule.direction
  access              = each.value.rule.access
  protocol            = each.value.rule.protocol
  source_port_range   = "*"
  source_address_prefixes = each.value.rule.source_prefixes
  resource_group_name         = var.resource_group
  network_security_group_name = azurerm_network_security_group.this[each.value.subnet].name

  # Use singular or plural depending on what's provided in the rule
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