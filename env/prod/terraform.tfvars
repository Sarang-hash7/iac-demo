environment = "prod"

location = "centralindia"

vnet_cidr = "10.20.0.0/16"

subnets = {
  app      = "10.20.1.0/24"
  db       = "10.20.2.0/24"
  future   = "10.20.3.0/24"
  postgres = "10.20.5.0/24"
}

subnet_delegations = {
  postgres = {
    service_name = "Microsoft.DBforPostgreSQL/flexibleServers"

    actions = [
      "Microsoft.Network/virtualNetworks/subnets/join/action"
    ]
  }
}

network_private_endpoint_subnet = {
  name                              = "PrivateEndpointSubnet"
  address_prefix                    = "10.20.4.0/24"
  private_endpoint_network_policies = "Disabled"
}

app_nsg_rules = [
  {
    name                   = "Allow-SSH-From-Local"
    priority               = 100
    direction              = "Inbound"
    access                 = "Allow"
    protocol               = "Tcp"
    source_prefixes        = ["103.241.182.128/32"]
    destination_port_range = "22"
  }
]

common_tags = {
  environment = "prod"
  project     = "webapp"
  owner       = "sarang.gupta@cloud4c.com"
}

kv_name = "kv-prod-56712"