##########################################
# Firewall Public IP
##########################################

resource "azurerm_public_ip" "this" {

  name                = "${var.firewall_name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name

  allocation_method = "Static"

  sku = var.public_ip_sku

  tags = var.tags
}

resource "azurerm_public_ip" "management" {

  name                = "${var.firewall_name}-management-pip"
  location            = var.location
  resource_group_name = var.resource_group_name

  allocation_method = "Static"

  sku = var.public_ip_sku

  tags = var.tags
}

##########################################
# Azure Firewall
##########################################

resource "azurerm_firewall" "this" {

  name                = var.firewall_name
  location            = var.location
  resource_group_name = var.resource_group_name

  sku_name = var.firewall_sku_name
  sku_tier = var.firewall_sku_tier

  firewall_policy_id = var.firewall_policy_id

  ip_configuration {

    name = "configuration"

    subnet_id = var.firewall_subnet_id

    public_ip_address_id = azurerm_public_ip.this.id
  }

  management_ip_configuration {

    name = "management"

    subnet_id = var.firewall_management_subnet_id

    public_ip_address_id = azurerm_public_ip.management.id
  }


  tags = var.tags
}