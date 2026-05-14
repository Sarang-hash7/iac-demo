variable "resource_group" {
  type = string
}

variable "location" {
  type = string
}

variable "environment" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "nsg_rules" {
  type = map(list(object({
    name                    = string
    priority                = number
    direction               = string
    access                  = string
    protocol                = string
    source_prefixes         = list(string)
    destination_port_range  = optional(string)
    destination_port_ranges = optional(list(string))
  })))

  default = {}
}

variable "subnet_map" {
  type    = map(string)
  default = {}
}