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
    destination_port_range  = optional(string)       # ← single port
    destination_port_ranges = optional(list(string)) # ← multiple ports
  }))
  default = [
    {
      name                   = "Allow-HTTP"
      priority               = 100
      direction              = "Inbound"
      access                 = "Allow"
      protocol               = "Tcp"
      source_prefixes        = ["Internet"]
      destination_port_range = "80" # ← singular
    },
    {
      name                   = "Allow-HTTPS"
      priority               = 110
      direction              = "Inbound"
      access                 = "Allow"
      protocol               = "Tcp"
      source_prefixes        = ["Internet"]
      destination_port_range = "443" # ← singular
    }
  ]
}

variable "subnet_map" {
  type    = map(string)
  default = {}
}