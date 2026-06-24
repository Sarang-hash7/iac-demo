environment = "prod-dr"

location = "southindia"

vnet_cidr = "10.30.0.0/16"

subnets = {
  app      = "10.30.1.0/24"
  postgres = "10.30.2.0/24"
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
  address_prefix                    = "10.30.3.0/24"
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
  },

  {
    name                   = "Allow-Flask-From-Local"
    priority               = 110
    direction              = "Inbound"
    access                 = "Allow"
    protocol               = "Tcp"
    source_prefixes        = ["103.241.182.128/32"]
    destination_port_range = "5000"
  }
]

common_tags = {
  environment = "prod-dr"
  project     = "webapp"
  owner       = "sarang.gupta@cloud4c.com"
}

kv_name = "kv-prod-dr-56712"
