variable "firewall_name" {
  description = "Name of the Azure Firewall"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource Group where the firewall will be created"
  type        = string
}

variable "firewall_sku_name" {
  description = "Firewall SKU name"
  type        = string
  default     = "AZFW_VNet"
}

variable "firewall_sku_tier" {
  description = "Firewall SKU tier"
  type        = string
  default     = "Basic"
}

variable "firewall_policy_id" {
  description = "Azure Firewall Policy ID"
  type        = string
}

variable "firewall_subnet_id" {
  description = "AzureFirewallSubnet ID"
  type        = string
}

variable "firewall_management_subnet_id" {
  description = "AzureFirewallManagementSubnet ID"
  type        = string
}

variable "public_ip_sku" {
  description = "Public IP SKU"
  type        = string
  default     = "Standard"
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}