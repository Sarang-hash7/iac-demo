variable "workspace_name" { type = string }
variable "location" { type = string }
variable "resource_group" { type = string }

variable "retention_in_days" {
  type        = number
  default     = 30          # ← minimum for PerGB2018 (was 7, only valid for Free SKU)
  description = "Retention in days. PerGB2018 SKU accepts 30-730 days."

  validation {
    condition     = var.retention_in_days >= 30 && var.retention_in_days <= 730
    error_message = "retention_in_days must be between 30 and 730 for PerGB2018 SKU."
  }
}

variable "daily_quota_gb" {
  type        = number
  default     = 0.4
  description = "Daily ingestion quota in GB. -1 means unlimited."
}

variable "vm_resource_ids" {
  type    = map(string)
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}