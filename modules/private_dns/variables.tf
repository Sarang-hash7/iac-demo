variable "dns_zone_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "vnet_links" {
  type = map(object({
    name    = string
    vnet_id = string
  }))
}