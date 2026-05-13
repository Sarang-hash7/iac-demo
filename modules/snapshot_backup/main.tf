locals {
  snapshot_start_time = format(
    "%sT%02d:%02d:00Z",
    var.snapshot_start_date,
    var.snapshot_schedule_hour_utc,
    var.snapshot_schedule_minute_utc
  )

  cleanup_start_time = format(
    "%sT%02d:%02d:00Z",
    var.cleanup_start_date,
    var.snapshot_schedule_hour_utc + 1,
    var.snapshot_schedule_minute_utc
  )
}
resource "azurerm_automation_runbook" "snapshot_vm" {
  name                    = "snapshot-vm"
  location                = var.location
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name

  log_verbose  = true
  log_progress = true

  runbook_type = "PowerShell"

  content = file("${path.module}/runbooks/snapshot-vm.ps1")
}

resource "azurerm_automation_runbook" "cleanup_snapshots" {
  name                    = "cleanup-snapshots"
  location                = var.location
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name

  log_verbose  = true
  log_progress = true

  runbook_type = "PowerShell"

  content = file("${path.module}/runbooks/cleanup-snapshots.ps1")
}

resource "azurerm_automation_schedule" "snapshot" {
  name                    = "daily-vm-snapshot"
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name

  frequency = "Day"
  interval  = 1

  timezone   = "UTC"
  start_time = local.snapshot_start_time

  description = "Daily VM snapshot schedule"
}

resource "azurerm_automation_schedule" "cleanup" {
  name                    = "daily-snapshot-cleanup"
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name

  frequency = "Day"
  interval  = 1

  timezone = "UTC"

  start_time = local.cleanup_start_time

  description = "Daily snapshot cleanup schedule"
}

resource "azurerm_automation_job_schedule" "snapshot" {
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name

  schedule_name = azurerm_automation_schedule.snapshot.name
  runbook_name  = azurerm_automation_runbook.snapshot_vm.name

  parameters = {
    resourcegroupname = var.snapshot_target_resource_group
    vmname            = var.snapshot_target_vm_name
    snapshotprefix    = var.snapshot_prefix
  }
}

resource "azurerm_automation_job_schedule" "cleanup" {
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name

  schedule_name = azurerm_automation_schedule.cleanup.name
  runbook_name  = azurerm_automation_runbook.cleanup_snapshots.name

  parameters = {
    resourcegroupname = var.snapshot_target_resource_group
    snapshotprefix    = var.snapshot_prefix
    retentionhours    = tostring(var.snapshot_retention_hours)
  }
}