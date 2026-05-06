variable "automation_account_name" { type = string }
variable "location" { type = string }
variable "resource_group" { type = string }
variable "resource_group_id" { type = string }
variable "vm_resource_ids" {
  type    = map(string)
  default = {}
}
variable "enable_auto_shutdown" {
  type    = bool
  default = true
}
variable "tags" {
  type    = map(string)
  default = {}
}
