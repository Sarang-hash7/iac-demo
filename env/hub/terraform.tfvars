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

common_tags = {
  environment = "hub"
  project     = "webapp"
  owner       = "sarang.gupta@cloud4c.com"
}