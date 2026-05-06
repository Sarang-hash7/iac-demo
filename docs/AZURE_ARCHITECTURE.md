# Azure Architecture Documentation

**Version**: 1.0  
**Date**: March 2026  
**Project**: IaC Demo - Hub/Spoke Network with Multi-Environment Deployment  
**Subscription Model**: Single subscription with RG-based isolation  

---

## 1. Architecture Overview

This solution implements a **hub-spoke network topology** on a single Azure subscription with environment-based resource group isolation (UAT, Prod, Hub). The architecture emphasizes network segmentation, centralized management, compliance, and secure deployment pipeline.

### Key Design Principles

- **Single Subscription**: Simplified billing and identity management
- **Resource Group Boundaries**: Logical isolation and RBAC at environment level
- **Network Isolation**: Hub/Spoke topology with centralized firewall/routing
- **GitOps Pipeline**: Infrastructure-as-code deployment with plan/approval/apply workflow
- **Security-First**: Managed identities, private keys in vault, audit logging, policy enforcement

---

## 2. Subscription & Resource Group Structure

### 2.1 Subscription Hierarchy

```
┌─────────────────────────────────────────────────────────────────────┐
│                    AZURE SUBSCRIPTION (Test)                        │
│                     sub-azure-test-001                              │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │          RESOURCE GROUP LAYER                               │  │
│  ├──────────────────────────────────────────────────────────────┤  │
│  │                                                              │  │
│  │  ┌─────────────────┐  ┌──────────────┐  ┌──────────────┐    │  │
│  │  │  RG-HUB         │  │  RG-UAT      │  │  RG-PROD     │    │  │
│  │  │  (Network Hub)  │  │  (Staging)   │  │  (Production)│    │  │
│  │  └─────────────────┘  └──────────────┘  └──────────────┘    │  │
│  │                                                              │  │
│  │  ┌──────────────────────────────────────────────────────┐   │  │
│  │  │  RG-SHARED (Optional)                               │   │  │
│  │  │  - Key Vault (secrets, SSH keys, certs)            │   │  │
│  │  │  - Log Analytics Workspace (centralized logging)   │   │  │
│  │  │  - Storage Account (Terraform state backend)       │   │  │
│  │  └──────────────────────────────────────────────────────┘   │  │
│  │                                                              │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### 2.2 Resource Group Definitions

| RG Name | Purpose | Key Components | Environment |
|---------|---------|-----------------|-------------|
| `RG-Hub` | Central networking control plane | Hub VNet, Azure Firewall, Bastion, Route Tables, NSGs | Shared |
| `RG-UAT` | Staging/UAT workloads | Spoke VNet (UAT), VMs, NSGs, LB, Application resources | UAT |
| `RG-Prod` | Production workloads | Spoke VNet (Prod), VMs, NSGs, LB, Application resources | Production |
| `RG-Shared` | Cross-cutting concerns | Key Vault, Log Analytics, Storage (state backend) | Shared |

---

## 3. Networking Architecture

### 3.1 Address Space Allocation

```
┌──────────────────────────────────────────────────────┐
│         SUBSCRIPTION ADDRESS SPACE                   │
│              10.0.0.0/8 (Reserved)                   │
│                                                      │
│  ┌────────────────────────────────────────────────┐  │
│  │  HUB VNET: 10.0.0.0/16                         │  │
│  │  Location: East US                             │  │
│  │  Subnets:                                       │  │
│  │  ├─ AzureFirewallSubnet: 10.0.1.0/24          │  │
│  │  ├─ BastionSubnet: 10.0.2.0/24                │  │
│  │  ├─ GatewaySubnet: 10.0.3.0/24 (Reserved)     │  │
│  │  └─ ManagementSubnet: 10.0.4.0/24 (Optional)  │  │
│  └────────────────────────────────────────────────┘  │
│                                                      │
│  ┌────────────────────────────────────────────────┐  │
│  │  UAT SPOKE VNET: 10.1.0.0/16                   │  │
│  │  Location: East US                             │  │
│  │  Subnets:                                       │  │
│  │  ├─ ApplicationSubnet: 10.1.1.0/24             │  │
│  │  ├─ DataSubnet: 10.1.2.0/24                   │  │
│  │  └─ ManagementSubnet: 10.1.3.0/24             │  │
│  └────────────────────────────────────────────────┘  │
│                                                      │
│  ┌────────────────────────────────────────────────┐  │
│  │  PROD SPOKE VNET: 10.2.0.0/16                  │  │
│  │  Location: East US                             │  │
│  │  Subnets:                                       │  │
│  │  ├─ ApplicationSubnet: 10.2.1.0/24             │  │
│  │  ├─ DataSubnet: 10.2.2.0/24                   │  │
│  │  └─ ManagementSubnet: 10.2.3.0/24             │  │
│  └────────────────────────────────────────────────┘  │
│                                                      │
└──────────────────────────────────────────────────────┘
```

### 3.2 Network Connectivity Model

```
                    INTERNET
                       |
                  Public IP (NAT)
                       |
         ┌─────────────────────────┐
         │   AZURE FIREWALL        │
         │   (Hub - 10.0.1.0/24)   │
         └──────────┬──────────────┘
                    |
        ┌───────────┴───────────┬────────────┐
        |                       |            |
    PEERING                PEERING      PEERING
        |                       |            |
 ┌──────────────┐    ┌──────────────┐  ┌──────────────┐
 │ HUB VNET     │    │ UAT SPOKE    │  │ PROD SPOKE   │
 │ 10.0.0.0/16 │    │ 10.1.0.0/16  │  │ 10.2.0.0/16  │
 │              │    │              │  │              │
 │ [Bastion]    │    │ [VMs]        │  │ [VMs]        │
 │ [FW]         │    │ [LB]         │  │ [LB]         │
 │ [Routes]     │    │ [Mgmt]       │  │ [Mgmt]       │
 └──────────────┘    └──────────────┘  └──────────────┘
```

### 3.3 Network Traffic Flow

**Inbound Traffic (Internet → Azure)**:
1. Public request arrives at Azure Firewall public IP
2. Firewall rules evaluate protocol/port/source
3. If allowed, traffic forwarded to appropriate spoke (UAT/Prod) via forced tunneling
4. NSG at spoke level applies additional filtering
5. Traffic reaches target VM/App

**Inter-Spoke Traffic (UAT ↔ Prod)**:
- Peering allows direct VNet-to-VNet communication
- Optional: Force through firewall using UDRs (User Defined Routes) on `0.0.0.0/0` → firewall

**Outbound Traffic (Azure → Internet)**:
- VMs in spokes route to firewall (UDR: `0.0.0.0/0` → firewall)
- Firewall NATs egress traffic
- Internet traffic appears from firewall public IP only

**Management Traffic**:
- Bastion host in Hub subnet allows SSH/RDP to VMs in spokes
- No direct public IPs on spoke VMs (zero-trust principle)

---

## 4. Security Model

### 4.1 Network Security

**Network Security Groups (NSGs)**:
- Hub: Allow firewall egress, SSH from management only
- UAT Spoke: Allow SSH from Bastion, internal app traffic, deny direct Internet inbound
- Prod Spoke: Stricter rules, allow only required service communication

**Azure Firewall**:
- **Rules**: Application rules (HTTP/HTTPS), Network rules (port/protocol filtering)
- **Threat Intelligence**: Block known malicious IPs
- **Logging**: Export to Log Analytics for audit

**User Defined Routes (UDRs)**:
- Spokes: `0.0.0.0/0` → Azure Firewall (forced tunneling)
- Hub: Local routes only, Internet routed naturally

### 4.2 Identity & Access Control

**Azure RBAC**:
- `Owner` role: Subscription admins only (limited scope)
- `Contributor` role: Pipeline service principal (scoped to specific RGs)
- `Network Contributor`: Network ops team (scoped to hub RG)
- `Reader`: Audit/monitoring roles (read-only)

**Service Principal**:
- Created for Azure DevOps pipeline
- Assigned `Contributor` at RG level (not subscription)
- Credentials stored in Key Vault secret
- Used for `az login` in pipeline via ARM service connection

**Managed Identities**:
- VMs assigned managed identity for secure service-to-service auth
- Access to Key Vault for secrets retrieval (e.g., app configuration)
- No credentials stored on VMs

### 4.3 Secrets & Key Management

**Azure Key Vault**:
- Store: SSH private keys, connection strings, API keys
- RBAC: Only authorized users/services can read
- Audit: All access logged to Azure Monitor
- Rotation: Lifecycle policies for automatic key rollover

**SSH Key Management**:
- Private key: Generated, stored in Key Vault, never in repo/pipeline
- Public key: Distributed via Terraform variable (safe, not a secret)
- Rotation: Regenerate and update Key Vault periodically

### 4.4 Compliance & Governance

**Azure Policy**:
- Enforce allowed locations (East US only)
- Enforce minimum SKUs (prevent expensive resources)
- Enforce tagging (cost center, owner, environment)
- Deny public IPs on spokes (zero-trust network)
- Enforce encryption (disks, storage)

**Audit Logging**:
- Activity Logs: All control plane operations
- Resource Diagnostics: NSG Flow Logs, Firewall logs
- VM Guest Logs: Application logs exported to Log Analytics

**Backup & Disaster Recovery**:
- VM backup: Daily snapshots in Azure Backup vault
- Log retention: 90 days minimum in Log Analytics
- State backend: Geo-redundant storage account

---

## 5. Resource Details

### 5.1 Compute Resources

**Virtual Machines (UAT & Prod)**:
- **OS**: Ubuntu 22.04 LTS
- **SKU**: Standard_B2s (UAT), Standard_D2s_v3 (Prod)
- **Authentication**: SSH key only (no password)
- **Managed Identity**: Enabled for Key Vault access
- **Tags**: Environment, Owner, CostCenter, DeploymentMethod="Terraform"

**Bastion Host**:
- **Location**: Hub RG
- **Subnet**: BastionSubnet (10.0.2.0/24)
- **SKU**: Basic (for demo), Standard for production
- **Purpose**: Secure RDP/SSH gateway to spoke VMs (no public IPs needed on spokes)

### 5.2 Networking Resources

**Virtual Networks & Subnets** (as defined in 3.1)

**Network Security Groups**:
- **Hub NSG**: Rules for firewall management, bastion egress
- **UAT NSG**: SSH from bastion, app-specific ingress rules
- **Prod NSG**: Stricter, production-grade filtering

**Route Tables**:
- **Hub Route Table**: Default routes, any spoke traffic handled by local gateways
- **UAT Route Table**: `0.0.0.0/0` → FW, local subnets direct
- **Prod Route Table**: Same as UAT, strict isolation

**Virtual Network Peering**:
- Hub ↔ UAT: Enabled, use remote gateway = true, allow forwarded traffic
- Hub ↔ Prod: Enabled, use remote gateway = true, allow forwarded traffic
- UAT ↔ Prod: Optional (if cross-environment communication needed)

**Public IPs**:
- Azure Firewall public IP (for outbound NAT)
- Bastion public IP (for SSH/RDP access to Bastion)
- No public IPs on spoke VMs (security principle)

### 5.3 Storage Resources

**Storage Account** (Terraform State Backend):
- **Location**: East US
- **Redundancy**: GRS (Geo-Redundant Storage)
- **Container**: `terraform-state`
- **Access**: Service principal only, anonymous access disabled
- **Encryption**: Microsoft-managed keys (or CMK for higher security)
- **Versioning**: Enabled (state recovery)

**Log Analytics Workspace**:
- **Name**: `law-${environment}-${random}`
- **Retention**: 90 days (adjustable)
- **Linked Resources**: 
  - Diagnostics from NSGs, Firewall, VMs
  - Application logs via VM agent

---

## 6. Deployment & Operations

### 6.1 Infrastructure Deployment Flow

1. **Code Commit**: Developer pushes Terraform code to Git (main/feature branch)
2. **Pipeline Trigger**: Azure Pipelines triggered on push (via `azure-pipelines.yml`)
3. **Change Detection**: Git diff identifies modified environments
4. **Plan Stage**: 
   - Terraform init/plan per environment
   - Plan artifact created and published
   - Security scan: `tfsec`, `tflint`, `terraform validate`
5. **Approval Stage**: 
   - Manual approval gate (UAT auto-approve if applicable, Prod requires review)
   - Approver reviews plan artifact
   - Notification sent to stakeholder
6. **Apply Stage**: 
   - Download plan artifact
   - Terraform apply (auto-approve from plan file)
   - Publish deployment logs, outputs
   - Notify completion status

### 6.2 Post-Deployment Activities

**Drift Detection**:
- Scheduled pipeline job (daily)
- Runs `terraform plan -detailed-exitcode` on all environments
- Exit code 2 = drift detected
- Create Azure Boards work item for investigation/remediation

**Resource Tagging Compliance**:
- Policy ensures all resources have required tags
- Azure Policy remediation tasks auto-apply missing tags
- Report generated monthly for FinOps/Compliance

**Monitoring & Alerting**:
- Log Analytics queries for security events
- Firewall dropped packets → alert to ops team
- VM CPU/Memory thresholds → auto-scale or alert
- Failed SSH attempts → tracked in NSG flow logs

### 6.3 Scaling & Capacity Management

- **Vertical Scaling**: Update VM SKU in `terraform.tfvars`, re-apply
- **Horizontal Scaling**: Add VMs via variables, module instance count
- **Load Balancing**: Optional Azure Load Balancer in spoke for multi-VM apps
- **Auto-Scale**: Azure VMSS (Virtual Machine Scale Set) for stateless workloads

---

## 7. Terraform Implementation

### 7.1 Module Structure

```
IaCDemo/
├── modules/
│   ├── resource_group/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── network/
│   │   ├── hub/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   └── README.md
│   │   │
│   │   └── spoke/
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       ├── outputs.tf
│   │       └── README.md
│   │
│   ├── security/
│   │   ├── nsg/
│   │   ├── firewall/
│   │   └── bastion/
│   │
│   ├── compute/
│   │   ├── vm/
│   │   └── lb/
│   │
│   └── storage/
│       └── key_vault/
│
├── env/
│   ├── hub/
│   │   ├── main.tf
│   │   ├── backend.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars
│   │   └── outputs.tf
│   │
│   ├── uat/
│   │   ├── main.tf
│   │   ├── backend.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars
│   │   └── outputs.tf
│   │
│   └── prod/
│       ├── main.tf
│       ├── backend.tf
│       ├── variables.tf
│       ├── terraform.tfvars
│       └── outputs.tf
│
├── azure-pipelines.yml
├── .gitignore
└── README.md
```

### 7.2 Backend Configuration

Each environment maintains its own state file:

```
Storage Account: "stterraformstate"
Container: "terraform-state"
Files:
  - hub.tfstate (locked)
  - uat.tfstate (locked)
  - prod.tfstate (locked)
```

**Backend Block** (in each env `backend.tf`):
```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "RG-Shared"
    storage_account_name = "stterraformstate"
    container_name       = "terraform-state"
    key                  = "uat.tfstate"  # Changes per env
  }
}
```

---

## 8. High-Level Terraform Variables

### Global/Shared Variables

```hcl
variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "environment" {
  description = "Environment name (hub, uat, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "iacDemo"
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default = {
    managed_by  = "terraform"
    environment = "production"
  }
}
```

### Environment-Specific Variables

**Hub Environment** (env/hub/terraform.tfvars):
```hcl
environment = "hub"
location    = "eastus"

hub_vnet_address_space = ["10.0.0.0/16"]
firewall_subnet_prefix = "10.0.1.0/24"
bastion_subnet_prefix  = "10.0.2.0/24"
```

**UAT Environment** (env/uat/terraform.tfvars):
```hcl
environment = "uat"
vm_size     = "Standard_B2s"
vm_count    = 1

spoke_vnet_address_space = ["10.1.0.0/16"]
app_subnet_prefix        = "10.1.1.0/24"
data_subnet_prefix       = "10.1.2.0/24"
```

**Prod Environment** (env/prod/terraform.tfvars):
```hcl
environment = "prod"
vm_size     = "Standard_D2s_v3"
vm_count    = 2

spoke_vnet_address_space = ["10.2.0.0/16"]
app_subnet_prefix        = "10.2.1.0/24"
data_subnet_prefix       = "10.2.2.0/24"
```

---

## 9. Outputs

### Key Outputs (per environment)

**Hub Outputs**:
- Hub VNet ID, subnets
- Firewall public IP
- Bastion public IP
- Route table IDs

**Spoke Outputs** (UAT/Prod):
- Spoke VNet ID, subnets
- NSG IDs
- Load balancer IP (if applicable)
- VM private IPs, hostnames

---

## 10. Future Enhancements

1. **Terraform Cloud/Enterprise**: Centralized state, policy as code, VCS-driven workflow
2. **Azure Front Door**: Global load balancing across regions (if multi-region)
3. **API Management**: Centralized API gateway in hub
4. **Azure DevOps Agent**: Self-hosted agents in hub for isolated deployments
5. **Multi-Region**: Replicate hub/spoke to secondary region for DR
6. **Compliance**: Azure Blueprints, Azure Policy initiatives (CIS, PCI-DSS, HIPAA)

---

## 11. Naming Conventions

```
Format: {resource-type}-{environment}-{region-abbr}-{numeric}

Examples:
  - rg-hub-eus-001         (Resource Group)
  - vnet-hub-eus-001       (Virtual Network)
  - vm-app-uat-eus-01      (Virtual Machine)
  - nsg-spoke-prod-eus-01  (Network Security Group)
  - fw-eus-001             (Firewall)
  - law-iac-eus-001        (Log Analytics Workspace)
  - kv-shared-eus-001      (Key Vault)
```

---

## 12. Cost Estimation

| Component | SKU | Est. Monthly Cost (USD) |
|-----------|-----|------------------------|
| Virtual Machine (UAT) | Standard_B2s | $35 |
| Virtual Machine (Prod x2) | Standard_D2s_v3 | $150 |
| Azure Firewall | Standard | $1.25/hour (~$900) |
| Bastion | Standard | $100 |
| VNet & Peering | Fixed | ~$10 |
| Storage (State) | GRS | ~$5 |
| Log Analytics | Pay-as-you-go | ~$50 |
| **Total Monthly** | | ~$1,250 |

---

**Document Version**: 1.0  
**Last Updated**: March 31, 2026  
**Maintainer**: Infrastructure Team
