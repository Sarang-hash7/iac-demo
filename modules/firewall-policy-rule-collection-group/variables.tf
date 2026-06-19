variable "firewall_policy_id" {
  type = string
}

variable "rule_collection_group_name" {
  type = string
}

variable "priority" {
  type = number
}

##################################################
# Network Rule Collections
##################################################

variable "network_rule_collections" {

  type = list(object({

    name     = string
    priority = number
    action   = string

    rules = list(object({

      name = string

      protocols = list(string)

      source_addresses = list(string)

      destination_addresses = list(string)

      destination_ports = list(string)

    }))
  }))

  default = []
}

##################################################
# Application Rule Collections
##################################################

variable "application_rule_collections" {

  type = list(object({

    name     = string
    priority = number
    action   = string

    rules = list(object({

      name = string

      source_addresses = list(string)

      destination_fqdns = list(string)

      protocols = list(object({

        type = string
        port = number

      }))
    }))
  }))

  default = []
}

##################################################
# NAT Rule Collections
##################################################

variable "nat_rule_collections" {

  type = list(object({

    name     = string
    priority = number
    action   = string

    rules = list(object({

      name = string

      protocols = list(string)

      source_addresses = list(string)

      destination_address = string

      destination_ports = list(string)

      translated_address = string

      translated_port = string

    }))
  }))

  default = []
}