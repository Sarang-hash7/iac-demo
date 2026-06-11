variable "vnet_name" {
  type = string
}

variable "address_space" {
  type = string
}

variable "subnets" {
  type = map(string)
}

variable "subnet_name_overrides" {
  type    = map(string)
  default = {}
}

variable "resource_group" {
  type = string
}

variable "location" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "enable_service_endpoints" {
  type    = bool
  default = false
}

variable "subnet_delegations" {
  type = map(object({
    service_name = string
    actions      = list(string)
  }))

  default = {}
}

variable "private_endpoint_subnet" {
  type = object({
    name                              = string
    address_prefix                    = string
    private_endpoint_network_policies = string
  })
}