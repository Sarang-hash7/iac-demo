variable "workspace_name" { type = string }
variable "location" { type = string }
variable "resource_group" { type = string }
variable "retention_in_days" {
  type    = number
  default = 7
}

variable "daily_quota_gb" {
  type    = number
  default = 0.4
}

variable "vm_resource_ids" {
  type    = map(string)
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
