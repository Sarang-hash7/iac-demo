output "app_public_ip" {
  value = try(module.compute.app_public_ip, "")
}

output "db_private_ip" {
  value = try(module.compute.db_private_ip, "")
}

output "log_analytics_workspace_id" {
  value = try(module.monitoring.workspace_id, "")
}
