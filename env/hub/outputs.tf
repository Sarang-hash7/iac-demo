output "hub_vnet_id" {
  value = module.network.vnet_id
}

output "hub_vnet_name" {
  value = module.network.vnet_name
}

output "hub_private_dns_zone_id" {
  value = module.private_dns.dns_zone_id
}