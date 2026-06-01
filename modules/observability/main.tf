# ========================
# Azure Monitor Agent Extension
# ========================
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

  type_handler_version       = "1.29" # ← updated from 1.0
  auto_upgrade_minor_version = true

  tags = var.tags
}

# ========================
# Data Collection Rule — Linux Baseline
# ========================
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

  # ── Heartbeat flow ──────────────────────────────────────────
  data_flow {
    streams      = ["Microsoft-Heartbeat"]
    destinations = ["law-destination"]
  }

  # ── Performance metrics flow ─────────────────────────────────
  data_flow {
    streams      = ["Microsoft-InsightsMetrics"]
    destinations = ["law-destination"]
  }

  data_sources {
    performance_counter {
      name                          = "linux-perf-counters"
      streams                       = ["Microsoft-InsightsMetrics"]
      sampling_frequency_in_seconds = 60

      # ✅ Correct Linux counter format
      counter_specifiers = [
        "Memory(*) % Used Memory",
        "Memory(*) Available MBytes Memory",
        "Logical Disk(*) % Used Space",
        "Logical Disk(*) % Free Space",
        "Processor(*) % Processor Time"
      ]
    }
    # ← Removed incorrect extension/Heartbeat block
    # Heartbeat is automatic when Microsoft-Heartbeat is in data_flow
  }

  tags = var.tags
}

# ========================
# DCR Association to VMs
# ========================
resource "azurerm_monitor_data_collection_rule_association" "vm_assoc" {
  for_each = var.vms

  name                    = "assoc-${each.key}"
  target_resource_id      = each.value.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.linux_baseline.id

  depends_on = [
    azurerm_virtual_machine_extension.ama # ← ensure AMA is installed before association
  ]
}