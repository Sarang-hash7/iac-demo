variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "environment" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "action_group_email" {
  type = string
}

variable "log_analytics_workspace_id" {
  type = string
}

variable "key_vault_id" {
  type = string
}

variable "vm_alert_targets" {
  type = map(object({
    id      = string
    name    = string
    os_type = string
  }))
}

variable "cpu_threshold_percent" {
  type    = number
  default = 80
}

variable "memory_threshold_percent" {
  type    = number
  default = 80
}

variable "disk_threshold_percent" {
  type    = number
  default = 85
}

variable "evaluation_frequency" {
  type    = string
  default = "PT5M"
}

variable "window_duration" {
  type    = string
  default = "PT10M"
}

variable "cpu_window_size" {
  type    = string
  default = "PT15M"
}

variable "heartbeat_missing_duration" {
  type    = string
  default = "PT10M"
}

variable "disk_excluded_mounts" {
  type = list(string)
  default = [
    "_Total",
    "total",
    "/dev",
    "/dev/shm",
    "/proc",
    "/sys"
  ]
}

variable "disk_excluded_mount_prefixes" {
  type = list(string)
  default = [
    "/snap/",
    "/run"
  ]
}

variable "service_health_events" {
  type = list(string)
  default = [
    "Incident",
    "Maintenance",
    "ActionRequired",
    "Security"
  ]
}

variable "service_health_locations" {
  type = list(string)
  default = [
    "Global",
    "Central India"
  ]
}
