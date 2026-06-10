variable "name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "subnet_ids" {
  type = map(string)
}

variable "routes" {
  type = map(object({
    address_prefix = string
    next_hop_type  = string
    next_hop_ip    = string
  }))
}