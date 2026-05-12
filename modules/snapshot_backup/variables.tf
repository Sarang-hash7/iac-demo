variable "automation_account_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "snapshot_target_vm_name" {
  type = string
}

variable "snapshot_target_resource_group" {
  type = string
}

variable "snapshot_schedule_hour_utc" {
  type    = number
  default = 14
}

variable "snapshot_schedule_minute_utc" {
  type    = number
  default = 30
}

variable "snapshot_retention_hours" {
  type    = number
  default = 48
}

variable "snapshot_prefix" {
  type    = string
  default = "snapshot"
}