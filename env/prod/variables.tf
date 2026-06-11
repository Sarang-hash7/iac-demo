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

variable "vm_config" {
  type = map(object({
    vm_size         = string
    os_disk_size_gb = number
    os_disk_type    = string
    subnet          = string
    public_ip       = bool
    admin_username  = string
  }))

  default = {
    app = {
      vm_size         = "Standard_B2als_v2"
      os_disk_size_gb = 30
      os_disk_type    = "StandardSSD_LRS"
      subnet          = "app"
      public_ip       = true
      admin_username  = "azureuser"
    }
  }
}

variable "common_tags" {
  type = map(string)
}