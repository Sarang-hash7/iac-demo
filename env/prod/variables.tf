variable "environment" {
  type    = string
  default = "prod"
}

variable "location" {
  type    = string
  default = "centralindia"
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
  type = map(string)

  default = {}
}

variable "common_tags" {
  type = map(string)
}