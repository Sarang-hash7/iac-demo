provider "azurerm" {
  features {}
  # NOTE: For local development you may set `use_cli = true` temporarily.
  # CI must authenticate via an Azure DevOps Service Connection (SPN); do NOT rely on use_cli in CI.
}
