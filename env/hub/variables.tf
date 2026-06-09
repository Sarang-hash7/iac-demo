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

variable "nva_nsg_rules" {
  type = list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
  }))
}


variable "vm_config" {
  type = map(object({
    vm_size         = string
    os_disk_size_gb = number
    os_disk_type    = string
    subnet          = string
    public_ip       = bool
    admin_username  = string
    ip_forwarding   = optional(bool, false)
  }))
}

# ========================
# Common Tags
# ========================

variable "common_tags" {
  type = map(string)
}