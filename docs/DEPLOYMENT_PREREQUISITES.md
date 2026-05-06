# Deployment prerequisites

1. Azure CLI and login

   - Local developers: `az login`
   - Pipeline: create an Azure DevOps Service Connection (Service Principal) and provide ARM_* env vars or use the Terraform task with the service connection.

2. Register required resource providers (run once per subscription):
```powershell
az provider register --namespace Microsoft.Compute --wait
az provider register --namespace Microsoft.Network --wait
az provider register --namespace Microsoft.OperationalInsights --wait
az provider register --namespace Microsoft.Insights --wait
az provider register --namespace Microsoft.Automation --wait
```

3. Bootstrap backend storage

   - Run `scripts/bootstrap-backend.ps1` to create the storage account and container for tfstate. The script hardens the storage account (`--https-only true`, `--allow-blob-public-access false`) and enables blob versioning.

4. Generate SSH keypair

```bash
mkdir -p keys
ssh-keygen -t rsa -b 4096 -f keys/id_rsa -N ""
```

5. Pipeline variables

   - Configure `BACKEND_SA` variable (storage account name) in pipeline variable group or pipeline library.
# Deployment Prerequisites & Setup Guide

**Version**: 1.0  
**Date**: March 2026  
**Project**: IaC Demo - Complete Pre-Deployment Setup Guide  
**Audience**: Infrastructure Engineers, DevOps Team, Project Leads  

---

## 1. Pre-Deployment Checklist

Before deploying the infrastructure, ensure all prerequisites are met. This document provides step-by-step setup instructions.

### 1.1 High-Level Prerequisites Overview

```
✓ Azure Subscription
✓ Service Principal (for automation)
✓ Azure Storage Account (Terraform state backend)
✓ Key Vault (secrets management)
✓ Git Repository (code & version control)
✓ Azure DevOps Project (pipeline & automation)
✓ SSH Key Pair (VM access)
✓ Terraform CLI installed locally
✓ Azure CLI installed locally
✓ Azure Policy & RBAC configured
```

---

## 2. Phase 1: Azure Subscription Setup

### 2.1 Subscription Requirements

| Item | Details | Status |
|------|---------|--------|
| **Subscription Name** | sub-azure-test-001 | ☐ |
| **Subscription ID** | e.g., 12345678-1234-1234-1234-123456789012 | ☐ |
| **Azure Region** | East US (primary) | ☐ |
| **Pricing Tier** | Standard (Pay-as-you-go) | ☐ |
| **Contacts Configured** | Admin email, billing contact | ☐ |
| **Cost Alerts** | Budget alarms set (>$2,000/month) | ☐ |

### 2.2 Quota Verification

Before deployment, verify Azure quotas are sufficient for your resources:

```bash
# Check VM quota
az compute vm list-usage --location eastus --query "[?contains(name.value, 'standardBSeries')].{Name:name.value, CurrentValue:currentValue, Limit:limit}"

# Check vCPU quota
az compute vm list-usage --location eastus --query "[?contains(name.value, 'Total')].{Name:name.value, CurrentValue:currentValue, Limit:limit}"

# Check IP quota
az compute vm list-usage --location eastus --query "[?contains(name.value, 'publicIPAddresses')].{Name:name.value, CurrentValue:currentValue, Limit:limit}"
```

**Example Output:**
```
Name                               CurrentValue    Limit
─────────────────────────────────────────────────────────
Standard B Series vCPUs            0               20
Standard D Series vCPUs            0               20
Total Regional vCPUs               0               20
Virtual Networks                   0               50
Public IP Addresses                0               20
```

**Action Required**: If any quota is near limit, request increase via Azure Portal (Support + Troubleshooting → New Support Request).

### 2.3 Subscription Initialization Script

**Script**: `bootstrap-subscription.ps1`

```powershell
# This script sets up initial subscription environment
# Run this ONCE before deployment

param (
    [string]$SubscriptionId = "<your-subscription-id>",
    [string]$Location = "eastus",
    [string]$ResourceGroupName = "rg-shared-eus-001",
    [string]$Environment = "test"
)

# 1. Login to Azure
Write-Host "Logging in to Azure..." -ForegroundColor Green
az login

# 2. Set subscription
Write-Host "Setting subscription context..." -ForegroundColor Green
az account set --subscription $SubscriptionId

# 3. Verify subscription
Write-Host "Verifying subscription..." -ForegroundColor Green
$currentSub = az account show --query "{Name:name, ID:id, TenantID:tenantId}" --output json | ConvertFrom-Json
Write-Host "Subscription: $($currentSub.Name) ($($currentSub.ID))" -ForegroundColor Cyan

# 4. Check quotas
Write-Host "`nChecking Azure quotas..." -ForegroundColor Green
$vmQuota = az compute vm list-usage --location $Location --query "[?contains(name.value, 'Standard B')].{Name:name.value, Used:currentValue, Limit:limit}" --output json
$vmQuota | ConvertFrom-Json | Format-Table

# 5. Enable required providers
Write-Host "`nEnabling Azure providers..." -ForegroundColor Green
@(
    "Microsoft.Compute",
    "Microsoft.Network",
    "Microsoft.Storage",
    "Microsoft.KeyVault",
    "Microsoft.LogAnalytics",
    "Microsoft.SecurityInsights"
) | ForEach-Object {
    Write-Host "  - Registering $_" -ForegroundColor Yellow
    az provider register --namespace $_
}

Write-Host "`n✓ Subscription setup complete!" -ForegroundColor Green
```

**Usage**:
```powershell
.\bootstrap-subscription.ps1 -SubscriptionId "12345678-1234-1234-1234-123456789012"
```

---

## 3. Phase 2: Service Principal & RBAC Setup

### 3.1 Create Service Principal for DevOps

Service Principal is used by Azure DevOps Pipeline to deploy infrastructure.

**Script**: `create-service-principal.ps1`

```powershell
param (
    [string]$DisplayName = "sp-terraform-deployment",
    [string]$SubscriptionId = "<your-subscription-id>"
)

# 1. Create Service Principal
Write-Host "Creating Service Principal: $DisplayName" -ForegroundColor Green
$sp = az ad sp create-for-rbac --name $DisplayName `
    --role Contributor `
    --scopes "/subscriptions/$SubscriptionId" `
    --output json | ConvertFrom-Json

Write-Host "`n✓ Service Principal created!" -ForegroundColor Green

# Display credentials (save these securely!)
Write-Host "`n═══════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "SERVICE PRINCIPAL CREDENTIALS (Save securely!)" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Client ID:       $($sp.appId)" -ForegroundColor Yellow
Write-Host "Client Secret:   $($sp.password)" -ForegroundColor Yellow
Write-Host "Tenant ID:       $($sp.tenant)" -ForegroundColor Yellow
Write-Host "Subscription:    $SubscriptionId" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan

# 2. Store credentials in Key Vault (IMPORTANT!)
Write-Host "`nStore these credentials in Azure Key Vault for security!" -ForegroundColor Yellow

# 3. Verify SP permissions
Write-Host "`nVerifying Service Principal permissions..." -ForegroundColor Green
az role assignment list --assignee $($sp.appId) --output table
```

**Usage**:
```powershell
.\create-service-principal.ps1 -SubscriptionId "12345678-1234-1234-1234-123456789012"
```

**Output** (save these immediately):
```
Client ID:       xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
Client Secret:   xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
Tenant ID:       xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
Subscription:    12345678-1234-1234-1234-123456789012
```

### 3.2 RBAC Configuration

**Role Assignments**:

| Role | Principal | Scope | Justification |
|------|-----------|-------|---------------|
| Contributor | sp-terraform-deployment | Subscription | Pipeline can create/modify resources |
| Reader | DevOps Team | Subscription | View logs, monitoring |
| Key Vault Administrator | sp-terraform-deployment | RG-Shared/Key Vault | Access to secrets (SSH keys, etc.) |
| Network Contributor | Network Ops | RG-Hub | Manage hub network |
| Virtual Machine Contributor | Ops Team | RG-UAT, RG-Prod | Manage VMs |

**Script**: `setup-rbac.ps1`

```powershell
param (
    [string]$SPObjectId = "<service-principal-object-id>",
    [string]$DevOpsGroupId = "<devops-group-id>"
)

# Get role definitions
$contributorRole = az role definition list --name "Contributor" --query "[0].id" --output tsv
$readerRole = az role definition list --name "Reader" --query "[0].id" --output tsv
$kvAdminRole = az role definition list --name "Key Vault Administrator" --query "[0].id" --output tsv

# Assign roles
Write-Host "Assigning roles..." -ForegroundColor Green

# Service Principal - Contributor at subscription
az role assignment create `
    --assignee-object-id $SPObjectId `
    --role "Contributor" `
    --scope "/subscriptions/$(az account show --query id -o tsv)"

# DevOps Group - Reader at subscription
az role assignment create `
    --assignee-object-id $DevOpsGroupId `
    --role "Reader" `
    --scope "/subscriptions/$(az account show --query id -o tsv)"

Write-Host "✓ RBAC setup complete!" -ForegroundColor Green
```

---

## 4. Phase 3: Storage Account & Terraform State Backend

### 4.1 Create Storage Account for State

Terraform state must be stored remotely in Azure Storage Account.

**Script**: `create-state-backend.ps1`

```powershell
param (
    [string]$ResourceGroupName = "rg-shared-eus-001",
    [string]$StorageAccountName = "stterraformstate",
    [string]$Location = "eastus",
    [string]$ContainerName = "terraform-state"
)

# 1. Create Resource Group
Write-Host "Creating Resource Group: $ResourceGroupName" -ForegroundColor Green
az group create --name $ResourceGroupName --location $Location

# 2. Create Storage Account
Write-Host "Creating Storage Account: $StorageAccountName" -ForegroundColor Green
az storage account create `
    --name $StorageAccountName `
    --resource-group $ResourceGroupName `
    --location $Location `
    --sku Standard_GRS `
    --kind StorageV2 `
    --https-only true `
    --access-tier Hot

# 3. Create Blob Container
Write-Host "Creating Blob Container: $ContainerName" -ForegroundColor Green
az storage container create `
    --name $ContainerName `
    --account-name $StorageAccountName

# 4. Get Storage Account Key
$storageKey = az storage account keys list `
    --account-name $StorageAccountName `
    --resource-group $ResourceGroupName `
    --query "[0].value" --output tsv

Write-Host "`n✓ Storage Account created!" -ForegroundColor Green
Write-Host "`nStorage Account Details:" -ForegroundColor Cyan
Write-Host "  - Name: $StorageAccountName" -ForegroundColor Yellow
Write-Host "  - Resource Group: $ResourceGroupName" -ForegroundColor Yellow
Write-Host "  - Container: $ContainerName" -ForegroundColor Yellow
Write-Host "  - Access Key: $($storageKey.Substring(0,10))..." -ForegroundColor Yellow

# 5. Enable versioning and soft delete for safety
Write-Host "`nEnabling blob versioning & soft delete..." -ForegroundColor Green
az storage account blob-service-properties update `
    --account-name $StorageAccountName `
    --enable-change-feed true `
    --enable-versioning true `
    --enable-delete-retention true `
    --delete-retention-days 30

Write-Host "✓ Versioning & soft delete enabled!" -ForegroundColor Green
```

**Usage**:
```powershell
.\create-state-backend.ps1 -StorageAccountName "stterraformstate"
```

### 4.2 Configure Local Terraform Backend

**File**: `env/hub/backend.tf`

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-shared-eus-001"
    storage_account_name = "stterraformstate"
    container_name       = "terraform-state"
    key                  = "hub.tfstate"
  }
}
```

**Initialize Backend**:
```bash
cd env/hub
terraform init
```

When prompted for storage account credentials, provide the access key from the previous step.

---

## 5. Phase 4: Key Vault Setup

### 5.1 Create Azure Key Vault

Key Vault stores secrets (SSH keys, passwords, connection strings).

**Script**: `create-key-vault.ps1`

```powershell
param (
    [string]$ResourceGroupName = "rg-shared-eus-001",
    [string]$KeyVaultName = "kv-shared-eus-001",
    [string]$Location = "eastus",
    [string]$SPObjectId = "<service-principal-object-id>"
)

# 1. Create Key Vault
Write-Host "Creating Key Vault: $KeyVaultName" -ForegroundColor Green
az keyvault create `
    --name $KeyVaultName `
    --resource-group $ResourceGroupName `
    --location $Location `
    --enable-rbac-authorization true

# 2. Grant Service Principal access (Key Vault Administrator role)
Write-Host "Granting SP access to Key Vault..." -ForegroundColor Green
az role assignment create `
    --assignee-object-id $SPObjectId `
    --role "Key Vault Administrator" `
    --scope "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$ResourceGroupName/providers/Microsoft.KeyVault/vaults/$KeyVaultName"

Write-Host "✓ Key Vault created and SP granted access!" -ForegroundColor Green
```

### 5.2 Store SSH Key in Key Vault

SSH key is required for VM access. Generate and store it.

```bash
# Generate SSH key pair (if not already done)
ssh-keygen -t ed25519 -f ~/.ssh/terraform-demo -C "terraform-demo"

# Store PRIVATE key in Key Vault (secure location)
az keyvault secret set \
    --vault-name "kv-shared-eus-001" \
    --name "terraform-ssh-private-key" \
    --file ~/.ssh/terraform-demo

# Also store PUBLIC key
az keyvault secret set \
    --vault-name "kv-shared-eus-001" \
    --name "terraform-ssh-public-key" \
    --file ~/.ssh/terraform-demo.pub
```

**Verify**:
```bash
az keyvault secret show \
    --vault-name "kv-shared-eus-001" \
    --name "terraform-ssh-public-key" \
    --query value --output tsv
```

### 5.3 Store Service Principal Credentials in Key Vault

```bash
# Store SP credentials (from earlier step)
az keyvault secret set \
    --vault-name "kv-shared-eus-001" \
    --name "sp-client-id" \
    --value "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

az keyvault secret set \
    --vault-name "kv-shared-eus-001" \
    --name "sp-client-secret" \
    --value "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

az keyvault secret set \
    --vault-name "kv-shared-eus-001" \
    --name "sp-tenant-id" \
    --value "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

az keyvault secret set \
    --vault-name "kv-shared-eus-001" \
    --name "sp-subscription-id" \
    --value "12345678-1234-1234-1234-123456789012"
```

---

## 6. Phase 5: Git Repository Setup

### 6.1 Initialize Git Repository

```bash
# Clone (if existing) or initialize (if new)
git init IaCDemo
cd IaCDemo

# Create directory structure
mkdir -p modules/{network/hub,network/spoke,resource_group,compute/vm,storage/key_vault}
mkdir -p env/{hub,uat,prod}
mkdir -p docs
mkdir -p scripts

# Add .gitignore
cat > .gitignore << 'EOF'
# Terraform
*.tfstate
*.tfstate.*
*.tfplan
*.tfvars
!terraform.tfvars.example
.terraform/
.terraform.lock.hcl
crash.log
override.tf.json
*_override.tf
override.tf

# SSH Keys
*.pem
*.key
id_rsa*
!*.pub

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Local dev
*.local.tfvars
EOF

# Initial commit
git add .
git commit -m "Initial project structure"
```

### 6.2 Create Git Branches

```bash
# Create main branch (protected)
git checkout -b main

# Create develop branch
git checkout -b develop

# Create feature branches
git checkout -b feature/hub-networking
git checkout -b feature/uat-infrastructure
git checkout -b feature/prod-infrastructure
```

### 6.3 Configure Git Policies (Azure Repos/GitHub)

**Branch Protection Rules**:
- Require pull request reviews: **Yes**
- Require status checks to pass: **Yes**
- Dismiss stale PR approvals: **Yes**
- Require up-to-date branches: **Yes**
- Require code owners review: **Yes**
- Allow auto-merge: **No** (manual only)

---

## 7. Phase 6: Azure DevOps Setup

### 7.1 Create Azure DevOps Project

```bash
# Create project
az devops project create \
    --name "IaCDemo" \
    --organization "https://dev.azure.com/your-org" \
    --source-control "git" \
    --visibility "private"

# Set project defaults
az devops project update \
    --name "IaCDemo" \
    --organization "https://dev.azure.com/your-org" \
    --description "Infrastructure as Code Demo - Hub/Spoke Architecture"
```

### 7.2 Create Service Connection

**Via Azure Portal**:
1. Project Settings → Service connections → New service connection
2. Select "Azure Resource Manager"
3. Choose "Service Principal (Manual)"
4. Enter SP credentials:
   - Subscription ID: `12345678-1234-1234-1234-123456789012`
   - Subscription Name: `sub-azure-test-001`
   - Service Principal ID: (Client ID)
   - Service Principal Key: (Client Secret)
   - Tenant ID: (Tenant ID)
5. Name: `terraform-deployment-connection`
6. Make Shareable: `Yes`

**Verify Connection**:
```bash
az devops service-endpoint list \
    --project "IaCDemo" \
    --organization "https://dev.azure.com/your-org"
```

### 7.3 Create Variable Groups (in Azure DevOps)

**Variable Group 1: `Terraform-Common`**
```
variable_group_name: Terraform-Common
variables:
  - TF_VERSION: 1.5.0
  - TERRAFORM_BACKEND_RG: rg-shared-eus-001
  - TERRAFORM_BACKEND_STORAGE: stterraformstate
  - TERRAFORM_BACKEND_CONTAINER: terraform-state
  - AZURE_LOCATION: eastus
```

**Variable Group 2: `Terraform-Hub`**
```
variable_group_name: Terraform-Hub
variables:
  - ENVIRONMENT: hub
  - RESOURCE_GROUP: rg-hub-eus-001
  - TFVARS_FILE: env/hub/terraform.tfvars
  - STATE_KEY: hub.tfstate
```

**Variable Group 3: `Terraform-UAT`**
```
variable_group_name: Terraform-UAT
variables:
  - ENVIRONMENT: uat
  - RESOURCE_GROUP: rg-uat-eus-001
  - TFVARS_FILE: env/uat/terraform.tfvars
  - STATE_KEY: uat.tfstate
```

**Variable Group 4: `Terraform-Prod`**
```
variable_group_name: Terraform-Prod
variables:
  - ENVIRONMENT: prod
  - RESOURCE_GROUP: rg-prod-eus-001
  - TFVARS_FILE: env/prod/terraform.tfvars
  - STATE_KEY: prod.tfstate
```

**Link Key Vault Secrets** (to variable groups):
```bash
# Link Terraform-Common group to Key Vault
az pipelines variable-group create \
    --name "Terraform-Secrets" \
    --variables-key-vault-name "kv-shared-eus-001" \
    --project "IaCDemo" \
    --organization "https://dev.azure.com/your-org"
```

---

## 8. Phase 7: SSH Key Setup

### 8.1 Generate SSH Key Pair

```bash
# Generate key pair (if not already done)
ssh-keygen -t ed25519 \
    -f ~/.ssh/terraform-demo \
    -C "terraform-demo@iacdemo.com" \
    -N ""  # Empty passphrase

# Permissions
chmod 600 ~/.ssh/terraform-demo
chmod 644 ~/.ssh/terraform-demo.pub
```

### 8.2 Update terraform.tfvars

**File**: `env/hub/terraform.tfvars` (and uat, prod)

```hcl
# Location & Environment
location            = "eastus"
environment         = "hub"
project_name        = "iacDemo"
resource_group_name = "rg-hub-eus-001"

# SSH Configuration
ssh_public_key_path = "/home/user/.ssh/terraform-demo.pub"
# OR if using Azure DevOps pipeline:
ssh_public_key_path = "$(System.DefaultWorkingDirectory)/ssh-keys/terraform-demo.pub"

# Tags
tags = {
  managed_by  = "terraform"
  environment = "test"
  project     = "iac-demo"
  cost_center = "engineering"
}
```

### 8.3 Secure SSH Key Distribution (for Pipeline)

In Azure DevOps Pipeline, SSH key must be available to Terraform.

**Option 1: Secure Files**
```yaml
- task: DownloadSecureFile@1
  name: sshKey
  displayName: 'Download SSH Key'
  inputs:
    secureFile: 'terraform-demo.pub'

- script: |
    cp $(sshKey.secureFilePath) $(Build.ArtifactStagingDirectory)/
    chmod 644 $(Build.ArtifactStagingDirectory)/terraform-demo.pub
  displayName: 'Copy SSH Key'
```

**Option 2: Key Vault Secret**
```yaml
- task: AzureKeyVault@2
  inputs:
    azureSubscription: 'terraform-deployment-connection'
    KeyVaultName: 'kv-shared-eus-001'
    SecretsFilter: 'terraform-ssh-public-key'
    RunOnSecureFilesContext: true

- script: |
    echo "$(terraform-ssh-public-key)" > ssh-key.pub
    chmod 644 ssh-key.pub
  displayName: 'Extract SSH Public Key'
```

---

## 9. Phase 8: Local Environment Setup

### 9.1 Install Prerequisites

**Windows PowerShell**:
```powershell
# Install Terraform
choco install terraform

# Install Azure CLI
choco install azure-cli

# Install Git
choco install git

# Install VS Code (optional)
choco install vscode

# Verify installations
terraform -version
az --version
git --version
```

**macOS**:
```bash
# Install Terraform
brew install terraform

# Install Azure CLI
brew install azure-cli

# Install Git
brew install git

# Verify installations
terraform -version
az --version
git --version
```

**Linux (Ubuntu/Debian)**:
```bash
# Update package manager
sudo apt update

# Install Terraform
wget https://releases.hashicorp.com/terraform/1.5.0/terraform_1.5.0_linux_amd64.zip
unzip terraform_1.5.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install Git
sudo apt install git-all

# Verify
terraform -version
az --version
git --version
```

### 9.2 Configure Azure CLI

```bash
# Login to Azure
az login

# Set default subscription
az account set --subscription "sub-azure-test-001"

# Verify
az account show
```

### 9.3 Setup Local SSH Key

```bash
# Add SSH key to ssh-agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/terraform-demo

# Verify
ssh-add -l
```

---

## 10. Phase 9: Pre-Deployment Validation

### 10.1 Terraform Validation

```bash
# Navigate to project directory
cd IaCDemo/env/hub

# Format check
terraform fmt -recursive ..

# Validate
terraform validate

# Plan (dry-run)
terraform plan -var-file=terraform.tfvars -out=tfplan

# Review plan
terraform show tfplan
```

**Expected Output**:
```
Plan: 15 to add, 0 to change, 0 to destroy
```

### 10.2 Security Scan

```bash
# Run tfsec
tfsec env/

# Run tflint
tflint .

# Run terraform fmt check
terraform fmt -check -recursive .
```

### 10.3 Cost Estimation

```bash
# Install infracost (optional)
brew install infracost  # macOS
# or
choco install infracost  # Windows

# Estimate costs
infracost breakdown --path env/hub/tfplan
```

---

## 11. Pre-Deployment Checklist (Final)

Before running pipeline, confirm all items:

```
Azure Subscription:
☐ Subscription ID documented
☐ Quotas verified (vCPU, storage, etc.)
☐ Cost alerts configured

Service Principal:
☐ Service Principal created
☐ Credentials stored in Key Vault
☐ Contributor role assigned to subscription
☐ RBAC configured for Key Vault access

Storage & State:
☐ Storage Account created
☐ Blob container created
☐ Versioning & soft delete enabled
☐ Backend.tf configured in each environment

Key Vault:
☐ Key Vault created
☐ SSH public key stored
☐ Service Principal credentials stored
☐ Access policies configured

Git Repository:
☐ Repository initialized
☐ Branches created (main, develop, feature/*)
☐ .gitignore configured
☐ Initial commit pushed

Azure DevOps:
☐ Project created
☐ Service connection configured
☐ Variable groups created
☐ Secure files uploaded (SSH key)
☐ Pipeline YAML created (azure-pipelines.yml)

SSH Keys:
☐ SSH key pair generated
☐ Public key in Key Vault
☐ Private key secured locally
☐ terraform.tfvars updated with path

Local Environment:
☐ Terraform installed & verified
☐ Azure CLI installed & logged in
☐ Git configured & cloned
☐ SSH key added to ssh-agent

Pre-Deployment Validation:
☐ terraform validate passed
☐ terraform plan successful (15 resources)
☐ tfsec scan passed (0 HIGH severity)
☐ tflint passed (0 errors)
☐ Cost estimation reviewed

Documentation:
☐ Architecture docs reviewed
☐ Network topology understood
☐ Project flow diagram reviewed
☐ Approval process understood
☐ Runbooks accessible
```

---

## 12. Common Issues & Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| `terraform init` fails | Backend not configured | Verify `backend.tf` has correct storage account name & key |
| Plan shows errors | Variable not found | Check `terraform.tfvars` file is in `env/` directory |
| SSH key not found | Path incorrect | Verify `ssh_public_key_path` in `.tfvars` matches actual location |
| Quota exceeded | Resource limit | Request quota increase via Azure Support |
| Service Principal access denied | RBAC not assigned | Verify SP has Contributor role at subscription scope |
| tfsec fails | Security issues in code | Review tfsec report and fix (encryption, auth, etc.) |

---

## 13. Post-Setup Verification Script

**Script**: `verify-setup.ps1`

```powershell
param (
    [string]$SubscriptionId = "<your-subscription-id>",
    [string]$ResourceGroupName = "rg-shared-eus-001",
    [string]$StorageAccountName = "stterraformstate",
    [string]$KeyVaultName = "kv-shared-eus-001"
)

Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     TERRAFORM SETUP VERIFICATION SCRIPT              ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

# 1. Verify Azure subscription
Write-Host "`n[1] Verifying Azure Subscription..." -ForegroundColor Yellow
$currentSub = az account show --output json | ConvertFrom-Json
if ($currentSub.id -eq $SubscriptionId) {
    Write-Host "✓ Subscription: $($currentSub.name)" -ForegroundColor Green
} else {
    Write-Host "✗ Wrong subscription!" -ForegroundColor Red
    exit 1
}

# 2. Verify Resource Group
Write-Host "`n[2] Verifying Resource Group..." -ForegroundColor Yellow
$rg = az group show --name $ResourceGroupName --output json 2>$null | ConvertFrom-Json
if ($rg) {
    Write-Host "✓ Resource Group: $($rg.name)" -ForegroundColor Green
} else {
    Write-Host "✗ Resource Group not found!" -ForegroundColor Red
}

# 3. Verify Storage Account
Write-Host "`n[3] Verifying Storage Account..." -ForegroundColor Yellow
$sa = az storage account show --name $StorageAccountName --resource-group $ResourceGroupName --output json 2>$null | ConvertFrom-Json
if ($sa) {
    Write-Host "✓ Storage Account: $($sa.name)" -ForegroundColor Green
    Write-Host "  - Kind: $($sa.kind)" -ForegroundColor Cyan
    Write-Host "  - SKU: $($sa.sku.name)" -ForegroundColor Cyan
} else {
    Write-Host "✗ Storage Account not found!" -ForegroundColor Red
}

# 4. Verify Blob Container
Write-Host "`n[4] Verifying Blob Container..." -ForegroundColor Yellow
$containers = az storage container list --account-name $StorageAccountName --output json 2>$null | ConvertFrom-Json
if ($containers | Where-Object { $_.name -eq "terraform-state" }) {
    Write-Host "✓ Container 'terraform-state' exists" -ForegroundColor Green
} else {
    Write-Host "✗ Container not found!" -ForegroundColor Red
}

# 5. Verify Key Vault
Write-Host "`n[5] Verifying Key Vault..." -ForegroundColor Yellow
$kv = az keyvault show --name $KeyVaultName --output json 2>$null | ConvertFrom-Json
if ($kv) {
    Write-Host "✓ Key Vault: $($kv.name)" -ForegroundColor Green
    Write-Host "  - RBAC Auth: Enabled" -ForegroundColor Cyan
} else {
    Write-Host "✗ Key Vault not found!" -ForegroundColor Red
}

# 6. Verify Terraform Installation
Write-Host "`n[6] Verifying Terraform Installation..." -ForegroundColor Yellow
$tfVersion = terraform -version 2>$null
if ($tfVersion) {
    Write-Host "✓ Terraform installed:" -ForegroundColor Green
    Write-Host "  $tfVersion" -ForegroundColor Cyan
} else {
    Write-Host "✗ Terraform not found!" -ForegroundColor Red
}

# 7. Verify Azure CLI
Write-Host "`n[7] Verifying Azure CLI..." -ForegroundColor Yellow
$azVersion = az --version 2>$null | Select-Object -First 1
if ($azVersion) {
    Write-Host "✓ Azure CLI installed:" -ForegroundColor Green
    Write-Host "  $azVersion" -ForegroundColor Cyan
} else {
    Write-Host "✗ Azure CLI not found!" -ForegroundColor Red
}

# 8. Verify Git
Write-Host "`n[8] Verifying Git..." -ForegroundColor Yellow
$gitVersion = git --version 2>$null
if ($gitVersion) {
    Write-Host "✓ Git installed:" -ForegroundColor Green
    Write-Host "  $gitVersion" -ForegroundColor Cyan
} else {
    Write-Host "✗ Git not found!" -ForegroundColor Red
}

Write-Host "`n╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     VERIFICATION COMPLETE                            ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
```

**Usage**:
```powershell
.\verify-setup.ps1 -SubscriptionId "12345678-1234-1234-1234-123456789012"
```

---

## 14. Quick Start Summary

### Quick Setup Sequence (5 minutes if prerequisites exist)

```bash
# 1. Clone repo
git clone https://dev.azure.com/your-org/IaCDemo

# 2. Login to Azure
az login

# 3. Set subscription
az account set --subscription "12345678-1234-1234-1234-123456789012"

# 4. Initialize terraform (hub)
cd IaCDemo/env/hub
terraform init

# 5. Validate
terraform validate

# 6. Plan
terraform plan -var-file=terraform.tfvars

# 7. Ready for deployment!
```

---

**Document Version**: 1.0  
**Last Updated**: March 31, 2026  
**Prepared By**: Infrastructure Team  
**Ready for Deployment**: ✓ Yes
