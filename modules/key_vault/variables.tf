variable "name" { type = string }
variable "location" { type = string }
variable "resource_group" { type = string }
variable "log_analytics_workspace_id" {
  type = string
}
variable "admin_object_id" {
  type = string
}

variable "pipeline_sp_object_id" {
  type = string
}

variable "network_acls" {
  type = object({
    default_action = string
    bypass         = string
    ip_rules       = list(string)
  })

  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
