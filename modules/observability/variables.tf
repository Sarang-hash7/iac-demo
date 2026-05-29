variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "log_analytics_workspace_id" {
  type = string
}

variable "vms" {
  type = map(object({
    id      = string
    os_type = string
  }))
}

variable "environment" {
  type = string
}

variable "tags" {
  type = map(string)
}