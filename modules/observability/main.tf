resource "azurerm_virtual_machine_extension" "ama" {
  for_each = var.vms

  name               = "AzureMonitorAgent"
  virtual_machine_id = each.value.id
  publisher          = "Microsoft.Azure.Monitor"

  type = (
    each.value.os_type == "windows"
    ? "AzureMonitorWindowsAgent"
    : "AzureMonitorLinuxAgent"
  )

  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true

  tags = var.tags
}

resource "azurerm_monitor_data_collection_rule" "linux_baseline" {
  name                = "dcr-${var.environment}-linux-baseline"
  location            = var.location
  resource_group_name = var.resource_group_name

  destinations {
    log_analytics {
      workspace_resource_id = var.log_analytics_workspace_id
      name                  = "law-destination"
    }
  }

  data_flow {
    streams = [
      "Microsoft-Heartbeat",
      "Microsoft-InsightsMetrics"
    ]

    destinations = ["law-destination"]
  }

  data_sources {
    performance_counter {
      name = "linux-perf-counters"
      streams = [
        "Microsoft-InsightsMetrics"
      ]
      sampling_frequency_in_seconds = 60

      counter_specifiers = [
        "\\Memory\\AvailableMB",
        "\\Memory\\UsedMemoryPercentage",
        "\\LogicalDisk\\UsedPercentage",
        "\\Processor\\UtilizationPercentage"
      ]
    }
    extension {
      streams = [
        "Microsoft-Heartbeat"
      ]

      extension_name = "Heartbeat"
      extension_json = jsonencode({})
      name           = "heartbeat-extension"
    }
  }

  tags = var.tags
}

resource "azurerm_monitor_data_collection_rule_association" "vm_assoc" {
  for_each = var.vms

  name                    = "assoc-${each.key}"
  target_resource_id      = each.value.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.linux_baseline.id
}