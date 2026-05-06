variable "environment" {
  type = string
}

variable "instance_index" {
  type = string
}
variable "resource_group" { type = string }
variable "location" { type = string }
variable "vm_config" {
  type = map(object({
    vm_size         = string
    os_disk_size_gb = number
    os_disk_type    = string
    subnet          = string
    public_ip       = bool
    admin_username  = string
  }))
}
variable "subnet_map" { type = map(string) }
variable "nsg_map" {
  type    = map(string)
  default = {}
}

variable "ssh_public_key" {
  type = string
}

variable "allowed_ports" {
  type    = list(number)
  default = [22, 80, 443]
}

variable "public_ip_sku" {
  type    = string
  default = "Standard"
}

variable "image_publisher" {
  type    = string
  default = "Canonical"
}

variable "image_offer" {
  type    = string
  default = "0001-com-ubuntu-server-jammy"
}

variable "image_sku" {
  type    = string
  default = "22_04-lts"
}

variable "image_version" {
  type    = string
  default = "latest"
}

variable "hardening_cloudinit_path" {
  type    = string
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
