output "prod_dr_resource_group_name" {
  value = module.resource_group.resource_group_name
}

output "prod_dr_vnet_id" {
  value = module.network.vnet_id
}

output "prod_dr_vnet_name" {
  value = module.network.vnet_name
}

output "prod_dr_private_endpoint_subnet_id" {
  value = module.network.private_endpoint_subnet_id
}

output "log_analytics_workspace_id" {
  value = try(module.monitoring.workspace_id, "")
}