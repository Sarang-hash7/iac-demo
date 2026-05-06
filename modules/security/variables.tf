variable "resource_group" { type = string }
variable "location" { type = string }
variable "environment" {
  type = string
}
variable "tags" {
  type    = map(string)
  default = {}
}

variable "nsg_rules" {
  type = list(object({
    name                    = string
    priority                = number
    direction               = string
    access                  = string
    protocol                = string
    source_prefixes         = list(string)
    destination_port_ranges = list(string)
  }))
  default = [
    {
      name                    = "Allow-HTTP"
      priority                = 100
      direction               = "Inbound"
      access                  = "Allow"
      protocol                = "Tcp"
      source_prefixes         = ["Internet"]
      destination_port_ranges = ["80"]
    },
    {
      name                    = "Allow-HTTPS"
      priority                = 110
      direction               = "Inbound"
      access                  = "Allow"
      protocol                = "Tcp"
      source_prefixes         = ["Internet"]
      destination_port_ranges = ["443"]
    }
  ]
}

variable "subnet_map" {
  type    = map(string)
  default = {}
}
