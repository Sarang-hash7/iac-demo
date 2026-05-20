terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate-uat"
    storage_account_name = "iacdemouat86503"
    container_name       = "tfstate"
    key                  = "projects/iacdemo/environments/uat/terraform.tfstate"
    use_azuread_auth     = true # ← forces Azure AD token for data plane
  }
}