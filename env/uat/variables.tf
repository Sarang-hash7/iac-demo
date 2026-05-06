# ========================
# Core Environment Config
# ========================

variable "environment" {
  type    = string
  default = "uat"
}

variable "location" {
  type    = string
  default = "centralindia"
}

# ========================
# Network Configuration
# ========================

variable "vnet_cidr" {
  type    = string
  default = "10.10.0.0/16"
}

variable "subnets" {
  type = map(string)
  default = {
    app    = "10.10.1.0/24"
    db     = "10.10.2.0/24"
    future = "10.10.3.0/24"
  }
}

# ========================
# Common Tags
# ========================

variable "common_tags" {
  type = map(string)
  default = {
    project     = "webapp"
    environment = "uat"
    owner       = "sarang.gupta@cloud4c.com"
  }
}

# ========================
# SSH Configuration
# ========================

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string

  validation {
    condition     = length(var.ssh_public_key) > 0
    error_message = "SSH public key must be provided."
  }
}

# ========================
# Security
# ========================

variable "allowed_ports" {
  type    = list(number)
  default = [22, 80, 443]
}

variable "nsg_rules" {
  type = list(object({
    name                    = string
    priority                = number
    direction               = string
    access                  = string
    protocol                = string
    source_prefixes         = list(string)
    destination_port_ranges = list(string)
  }))
  default = []
}

# ========================
# Compute Configuration
# ========================

variable "vm_config" {
  type = map(object({
    vm_size         = string
    os_disk_size_gb = number
    os_disk_type    = string
    subnet          = string
    public_ip       = bool
    admin_username  = string
  }))
  default = {
    app = {
      vm_size         = "B1ls"
      os_disk_size_gb = 30
      os_disk_type    = "StandardSSD_LRS"
      subnet          = "app"
      public_ip       = true
      admin_username  = "azureuser"
    }
    db = {
      vm_size         = "B1s"
      os_disk_size_gb = 30
      os_disk_type    = "StandardSSD_LRS"
      subnet          = "db"
      public_ip       = false
      admin_username  = "azureuser"
    }
  }
}

# ========================
# Monitoring
# ========================

variable "log_analytics_retention_days" {
  type    = number
  default = 7
}

variable "log_analytics_daily_quota_gb" {
  type    = number
  default = 0.4
}

# ========================
# Automation
# ========================

variable "enable_auto_shutdown" {
  type    = bool
  default = true
}