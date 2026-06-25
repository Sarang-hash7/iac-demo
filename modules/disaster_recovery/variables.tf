variable "vault_name" {
  type = string
}

variable "replication_policy_name" {
  type = string
}

variable "cache_storage_account_name" {
  type = string
}

variable "dr_location" {
  type = string
}

variable "primary_location" {
  type = string
}

variable "dr_resource_group" {
  type = string
}

variable "primary_resource_group" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}