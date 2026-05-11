data "azurerm_client_config" "current" {}

# =========================
# Resource Group
# =========================
resource "azurerm_resource_group" "bootstrap" {
  name     = "rg-tfstate-${var.environment}"
  location = var.location
}

# =========================
# Storage Account (TF State)
# =========================
resource "azurerm_storage_account" "tfstate" {
  name                = "iacdemouat86503"
  resource_group_name = azurerm_resource_group.bootstrap.name
  location            = azurerm_resource_group.bootstrap.location

  account_tier             = "Standard"
  account_replication_type = "LRS"

  min_tls_version = "TLS1_2"

  allow_nested_items_to_be_public = false

  blob_properties {

    versioning_enabled = true

    change_feed_enabled = true

    delete_retention_policy {
      days = 7
    }

    container_delete_retention_policy {
      days = 7
    }
  }

  tags = {
    environment = var.environment
    project     = var.project
  }
}

# =========================
# Storage Container
# =========================
resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}

