# ========================
# Core Environment Config
# ========================

variable "environment" {
  type = string
}

variable "location" {
  type = string
}

# ========================
# Network Configuration
# ========================

variable "vnet_cidr" {
  type = string
}

variable "subnets" {
  type = map(string)
}

variable "subnet_name_overrides" {
  type    = map(string)
  default = {}
}

variable "network_private_endpoint_subnet" {
  type = object({
    name                              = string
    address_prefix                    = string
    private_endpoint_network_policies = string
  })
}

# ========================
# Common Tags
# ========================

variable "common_tags" {
  type = map(string)
}