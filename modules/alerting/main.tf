data "azurerm_client_config" "current" {}

locals {
  action_group_name = "ag-${var.environment}-core"
  subscription_id   = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"

  disk_excluded_mounts_kql = join(", ", [
    for mount in var.disk_excluded_mounts : "'${mount}'"
  ])

  disk_excluded_mount_prefix_filters = join("\n", [
    for prefix in var.disk_excluded_mount_prefixes : "| where not(InstanceName startswith '${prefix}')"
  ])

  resource_health_targets = merge(
    {
      for key, vm in var.vm_alert_targets :
      key => {
        id   = vm.id
        name = vm.name
      }
    },
    {
      key_vault = {
        id   = var.key_vault_id
        name = "key-vault"
      }
      log_analytics = {
        id   = var.log_analytics_workspace_id
        name = "log-analytics"
      }
    }
  )
}

resource "azurerm_monitor_action_group" "core" {
  name                = local.action_group_name
  resource_group_name = var.resource_group_name
  short_name          = local.action_group_name
  enabled             = true
  tags                = var.tags

  email_receiver {
    name                    = "primary-email"
    email_address           = var.action_group_email
    use_common_alert_schema = true
  }
}

resource "azurerm_monitor_metric_alert" "vm_cpu" {
  for_each = var.vm_alert_targets

  name                     = "al-${each.value.name}-cpu-high"
  resource_group_name      = var.resource_group_name
  scopes                   = [each.value.id]
  description              = "Average CPU greater than ${var.cpu_threshold_percent}% for ${var.cpu_window_size}."
  severity                 = 2
  frequency                = var.evaluation_frequency
  window_size              = var.cpu_window_size
  auto_mitigate            = true
  enabled                  = true
  target_resource_type     = "Microsoft.Compute/virtualMachines"
  target_resource_location = var.location
  tags                     = var.tags

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.cpu_threshold_percent
  }

  action {
    action_group_id = azurerm_monitor_action_group.core.id
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "vm_memory" {
  for_each = var.vm_alert_targets

  name                    = "al-${each.value.name}-memory-high"
  resource_group_name     = var.resource_group_name
  location                = var.location
  scopes                  = [var.log_analytics_workspace_id]
  description             = "Average memory used greater than ${var.memory_threshold_percent}% for ${var.window_duration}."
  severity                = 2
  evaluation_frequency    = var.evaluation_frequency
  window_duration         = var.window_duration
  auto_mitigation_enabled = true
  enabled                 = true
  tags                    = var.tags

  criteria {
    query = <<-KQL
      Perf
      | where TimeGenerated > ago(10m)
      | where _ResourceId =~ "${each.value.id}"
      | where ObjectName == "Memory"
      | where CounterName in~ ("% Used Memory", "Used Memory %")
      | summarize AggregatedValue = avg(CounterValue)
    KQL

    time_aggregation_method = "Maximum"
    metric_measure_column   = "AggregatedValue"
    operator                = "GreaterThan"
    threshold               = var.memory_threshold_percent

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 2
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.core.id]
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "vm_disk" {
  for_each = var.vm_alert_targets

  name                    = "al-${each.value.name}-disk-high"
  resource_group_name     = var.resource_group_name
  location                = var.location
  scopes                  = [var.log_analytics_workspace_id]
  description             = "Any real filesystem greater than ${var.disk_threshold_percent}% used for ${var.window_duration}."
  severity                = 2
  evaluation_frequency    = var.evaluation_frequency
  window_duration         = var.window_duration
  auto_mitigation_enabled = true
  enabled                 = true
  tags                    = var.tags

  criteria {
    query = <<-KQL
      Perf
      | where TimeGenerated > ago(10m)
      | where _ResourceId =~ "${each.value.id}"
      | where ObjectName == "Logical Disk"
      | where CounterName == "% Used Space"
      | where InstanceName !in (${local.disk_excluded_mounts_kql})
      ${local.disk_excluded_mount_prefix_filters}
      | summarize MaxUsed = max(CounterValue) by InstanceName
      | summarize AggregatedValue = max(MaxUsed)
    KQL

    time_aggregation_method = "Maximum"
    metric_measure_column   = "AggregatedValue"
    operator                = "GreaterThan"
    threshold               = var.disk_threshold_percent

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 2
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.core.id]
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "vm_heartbeat_missing" {
  for_each = var.vm_alert_targets

  name                    = "al-${each.value.name}-heartbeat-missing"
  resource_group_name     = var.resource_group_name
  location                = var.location
  scopes                  = [var.log_analytics_workspace_id]
  description             = "Azure Monitor Agent heartbeat missing for more than ${var.heartbeat_missing_duration}."
  severity                = 2
  evaluation_frequency    = var.evaluation_frequency
  window_duration         = "PT30M"
  auto_mitigation_enabled = true
  enabled                 = true
  tags                    = var.tags

  criteria {
    query = <<-KQL
      let lastSeen = toscalar(
        Heartbeat
        | where TimeGenerated > ago(30m)
        | where _ResourceId =~ "${each.value.id}"
        | summarize max(TimeGenerated)
      );
      print AggregatedValue = iff(isnull(lastSeen) or lastSeen < ago(10m), 1, 0)
    KQL

    time_aggregation_method = "Maximum"
    metric_measure_column   = "AggregatedValue"
    operator                = "GreaterThan"
    threshold               = 0

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 2
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.core.id]
  }
}

resource "azurerm_monitor_activity_log_alert" "resource_health" {
  for_each = local.resource_health_targets

  name                = "al-${var.environment}-${each.key}-resource-health"
  resource_group_name = var.resource_group_name
  location            = "global"
  scopes              = [each.value.id]
  description         = "Resource Health alert for ${each.value.name}."
  enabled             = true
  tags                = var.tags

  criteria {
    category    = "ResourceHealth"
    resource_id = each.value.id

    resource_health {
      current  = ["Degraded", "Unavailable", "Unknown"]
      previous = ["Available", "Degraded", "Unavailable", "Unknown"]
      reason   = ["PlatformInitiated", "UserInitiated", "Unknown"]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.core.id
  }
}

resource "azurerm_monitor_activity_log_alert" "service_health" {
  name                = "al-${var.environment}-service-health"
  resource_group_name = var.resource_group_name
  location            = "global"
  scopes              = [local.subscription_id]
  description         = "Subscription Service Health alert for ${join(", ", var.service_health_locations)}."
  enabled             = true
  tags                = var.tags

  criteria {
    category = "ServiceHealth"

    service_health {
      events    = var.service_health_events
      locations = var.service_health_locations
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.core.id
  }
}
