environment = "hub"

location = "centralindia"

vnet_cidr = "10.0.0.0/16"

subnets = {
  gateway        = "10.0.1.0/24"
  bastion        = "10.0.2.0/24"
  sharedservices = "10.0.3.0/24"

  transit  = "10.0.5.0/24"
  firewall = "10.0.6.0/24"
}

subnet_name_overrides = {
  gateway = "GatewaySubnet"
  bastion = "AzureBastionSubnet"

  transit  = "TransitSubnet"
  firewall = "AzureFirewallSubnet"
}

network_private_endpoint_subnet = {
  name                              = "PrivateEndpointSubnet"
  address_prefix                    = "10.0.4.0/24"
  private_endpoint_network_policies = "Disabled"
}

vm_config = {
  nva = {
    vm_size         = "Standard_B2als_v2"
    os_disk_size_gb = 30
    os_disk_type    = "StandardSSD_LRS"
    subnet          = "transit"
    public_ip       = true
    admin_username  = "azureuser"
    ip_forwarding   = true
  }
}

nva_nsg_rules = [
  {
    name                       = "Allow-SSH-From-Local"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "103.241.182.128/32"
    destination_address_prefix = "*"
  }
]

common_tags = {
  environment = "hub"
  project     = "webapp"
  owner       = "sarang.gupta@cloud4c.com"
}