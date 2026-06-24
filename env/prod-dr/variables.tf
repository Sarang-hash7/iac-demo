variable "environment" {
  type    = string
  default = "prod-dr"
}

variable "location" {
  type    = string
  default = "southindia"
}

variable "vnet_cidr" {
  type = string
}

variable "subnets" {
  type = map(string)
}

variable "network_private_endpoint_subnet" {
  type = object({
    name                              = string
    address_prefix                    = string
    private_endpoint_network_policies = string
  })
}

variable "subnet_delegations" {
  type = map(object({
    service_name = string
    actions      = list(string)
  }))

  default = {}
}

variable "app_nsg_rules" {
  type = list(object({
    name                    = string
    priority                = number
    direction               = string
    access                  = string
    protocol                = string
    source_prefixes         = list(string)
    destination_port_range  = optional(string)
    destination_port_ranges = optional(list(string))
  }))

  default = []
}

variable "kv_name" {
  type        = string
  description = "Override Key Vault name to avoid soft-delete conflicts"
  default     = null
}

variable "common_tags" {
  type = map(string)
}