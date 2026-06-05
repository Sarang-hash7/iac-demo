output "prod_resource_group_name" {
  value = module.resource_group.resource_group_name
}

output "prod_vnet_id" {
  value = module.network.vnet_id
}

output "prod_vnet_name" {
  value = module.network.vnet_name
}

output "prod_private_endpoint_subnet_id" {
  value = module.network.private_endpoint_subnet_id
}