variable "location" {
  description = "Azure region to deploy resources into."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the Azure Resource Group to create."
  type        = string
}

variable "vm_size" {
  description = "Size of the Azure VM."
  type        = string
}

variable "admin_username" {
  description = "Admin username for the VM."
  type        = string
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key file to use for VM access. If empty, Terraform will use `./id_rsa.pub` in this repo."
  type        = string
}
