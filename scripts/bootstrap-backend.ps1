param(
  [string]$ResourceGroup = "rg-uat-webapp-01",
  [string]$Location = "centralindia",
  [string]$StorageAccountPrefix = "iacdemouat"
)

# Create resource group
az group create --name $ResourceGroup --location $Location

# Create globally-unique storage account name - adjust as needed
$sa = ($StorageAccountPrefix + (Get-Random -Maximum 99999)).ToLower()
az storage account create --name $sa --resource-group $ResourceGroup --sku Standard_LRS --kind StorageV2 --location $Location --https-only true --allow-blob-public-access false --min-tls-version TLS1_2

# Enable blob versioning
$key = az storage account keys list --account-name $sa --resource-group $ResourceGroup --query "[0].value" -o tsv
az storage blob service-properties update --account-name $sa --account-key $key --enable-versioning true | Out-Null

# Create container
az storage container create --name tfstate --account-name $sa --account-key $key | Out-Null

Write-Host "StorageAccount:" $sa
Write-Host "Container: tfstate"
Write-Host "Backend key pattern: projects/iacdemo/environments/uat/terraform.tfstate"

# Optionally register providers (preferred: run interactively via az cli beforehand)
Write-Host "If needed, register resource providers with: az provider register --namespace Microsoft.Compute --wait"
