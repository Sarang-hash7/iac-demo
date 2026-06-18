variable "firewall_policy_name" {
  description = "Name of the Azure Firewall Policy"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource Group where the Firewall Policy will be created"
  type        = string
}

variable "firewall_policy_sku" {
  description = "Firewall Policy SKU"
  type        = string
  default     = "Basic"
}

variable "dns_proxy_enabled" {
  description = "Enable DNS Proxy"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}