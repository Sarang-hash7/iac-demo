# Project Flow Diagram & Workflow Documentation

**Version**: 1.0  
**Date**: March 2026  
**Project**: IaC Demo - Complete Project Lifecycle Flow  
**Scope**: Development → Deployment → Production Operations  

---

## 1. Overall Project Lifecycle

```
╔════════════════════════════════════════════════════════════════════════════╗
║                    COMPLETE PROJECT LIFECYCLE FLOW                          ║
╚════════════════════════════════════════════════════════════════════════════╝

┌──────────────────────────────────────────────────────────────────────────────┐
│ PHASE 1: PLANNING & PREPARATION                                            │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  1.1 Requirement Gathering                                                  │
│      └─ Define environments (UAT, Prod), resource needs, security policy    │
│                                                                              │
│  1.2 Architecture Design                                                    │
│      ├─ Design Azure resource groups (Hub, UAT, Prod, Shared)             │
│      ├─ Design network topology (Hub/Spoke VNets, subnetting)             │
│      ├─ Design security model (NSGs, firewall, RBAC, key vault)           │
│      └─ Design Terraform module structure                                  │
│                                                                              │
│  1.3 Pre-requisites Setup                                                   │
│      ├─ Create Azure subscription / service principal                       │
│      ├─ Create storage account for Terraform state                          │
│      ├─ Setup Azure DevOps project / Git repository                         │
│      ├─ Generate SSH key pair (store in Key Vault)                          │
│      └─ Configure Azure Policy / compliance baseline                        │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│ PHASE 2: DEVELOPMENT & VERSION CONTROL                                     │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  2.1 Developer Workflow                                                     │
│      ├─ Developer clones Git repo locally                                   │
│      ├─ Creates feature branch (feature/hub-networking)                     │
│      ├─ Writes/modifies Terraform code                                      │
│      │  ├─ Modules (network/hub, network/spoke, compute/vm)               │
│      │  ├─ Environment configs (env/hub, env/uat, env/prod)               │
│      │  └─ Follows naming conventions & coding standards                   │
│      │                                                                      │
│      ├─ Pre-commit checks (local)                                           │
│      │  ├─ terraform fmt (formatting)                                       │
│      │  ├─ terraform validate (syntax)                                      │
│      │  ├─ tflint (linting)                                                 │
│      │  ├─ tfsec (security scan)                                            │
│      │  └─ terraform-docs (documentation)                                   │
│      │                                                                      │
│      ├─ Commit and push to feature branch                                   │
│      └─ Create Pull Request (PR) in Azure DevOps/GitHub                     │
│                                                                              │
│  2.2 Code Review Process                                                    │
│      ├─ Reviewers examine PR:                                               │
│      │  ├─ Code structure & modularity                                      │
│      │  ├─ Security best practices                                          │
│      │  ├─ Compliance requirements                                          │
│      │  ├─ Cost implications (resource sizing)                              │
│      │  └─ Documentation completeness                                       │
│      │                                                                      │
│      ├─ Approval/Request Changes                                            │
│      │  ├─ If approved: Ready for merge                                     │
│      │  └─ If changes needed: Developer updates code, re-request review    │
│      │                                                                      │
│      └─ Merge to main/develop branch (after approval)                       │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│ PHASE 3: GIT EVENT TRIGGER                                                 │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  3.1 Push to Main Branch                                                    │
│      ├─ Event: Code merged to main / main pushed                            │
│      └─ Trigger: azure-pipelines.yml webhook activated                      │
│                                                                              │
│  3.2 Change Detection (Automatic)                                           │
│      ├─ Pipeline runs: git diff HEAD~1 HEAD                                 │
│      ├─ Identifies changed files / environments                             │
│      │  ├─ env/hub/ modified → Plan Hub environment                         │
│      │  ├─ env/uat/ modified → Plan UAT environment                         │
│      │  ├─ env/prod/ modified → Plan Prod environment                       │
│      │  └─ modules/ modified → Plan all affected environments              │
│      └─ Result: List of impacted environments                               │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│ PHASE 4: AZURE PIPELINES EXECUTION (AUTO)                                  │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  STAGE 1: PLAN STAGE (Per Environment)                                      │
│  ────────────────────────────────────────                                   │
│                                                                              │
│  4.1 Checkout & Setup                                                       │
│      ├─ Checkout code from Git repo                                         │
│      ├─ Install Terraform CLI                                               │
│      ├─ Install tools: az CLI, tfsec, tflint, terraform-docs               │
│      └─ Authenticate to Azure (ARM Service Connection)                      │
│         └─ Service Principal credentials injected from Azure Key Vault      │
│                                                                              │
│  4.2 Per-Environment Job (Parallel for each env: Hub, UAT, Prod)           │
│      │                                                                      │
│      ├─ For Hub Environment:                                                │
│      │  ├─ cd env/hub                                                       │
│      │  ├─ terraform init -backend-config=...                              │
│      │  │  ├─ Download provider plugins (azurerm)                           │
│      │  │  ├─ Connect to remote backend (state storage)                     │
│      │  │  └─ Download existing state file (hub.tfstate)                    │
│      │  │                                                                   │
│      │  ├─ terraform validate                                               │
│      │  │  └─ Verify syntax, required variables, provider version          │
│      │  │                                                                   │
│      │  ├─ Run static analysis tools                                        │
│      │  │  ├─ tflint . (linting)                                            │
│      │  │  ├─ tfsec . (security scan)                                       │
│      │  │  └─ terraform fmt -check (formatting check)                       │
│      │  │                                                                   │
│      │  ├─ terraform plan -var-file=terraform.tfvars -out=hub.tfplan       │
│      │  │  ├─ Load variables from terraform.tfvars                          │
│      │  │  ├─ Load state (hub.tfstate from backend)                         │
│      │  │  ├─ Call module resources with configuration                      │
│      │  │  ├─ Compare desired vs current state                              │
│      │  │  ├─ Detect changes (create/update/delete)                         │
│      │  │  └─ Output plan artifact (binary file)                            │
│      │  │                                                                   │
│      │  ├─ terraform show hub.tfplan (display plan in JSON)                │
│      │  │  └─ Output: detailed resource changes (human-readable)            │
│      │  │                                                                   │
│      │  └─ Publish artifacts                                                │
│      │     ├─ Upload hub.tfplan to pipeline storage                         │
│      │     ├─ Upload plan JSON to artifact storage                          │
│      │     ├─ Upload tfsec/tflint reports                                   │
│      │     └─ Generate summary report (changes count, estimate)             │
│      │                                                                      │
│      ├─ For UAT Environment: (same steps as Hub, different paths)           │
│      │  ├─ cd env/uat                                                       │
│      │  ├─ terraform init -backend-config=key=uat.tfstate                  │
│      │  ├─ terraform plan ... -out=uat.tfplan                              │
│      │  └─ Publish artifacts (uat.tfplan, uat-plan.json, etc.)             │
│      │                                                                      │
│      └─ For Prod Environment: (same steps as Hub, different paths)          │
│         ├─ cd env/prod                                                      │
│         ├─ terraform init -backend-config=key=prod.tfstate                 │
│         ├─ terraform plan ... -out=prod.tfplan                             │
│         └─ Publish artifacts (prod.tfplan, prod-plan.json, etc.)           │
│                                                                              │
│  4.3 Plan Summary                                                            │
│      ├─ Log: 3 environments planned                                         │
│      ├─ Hub: 5 resources to create                                          │
│      ├─ UAT: 10 resources to create                                         │
│      ├─ Prod: 15 resources to create / 2 resources to update               │
│      └─ **PAUSE**: Awaiting approval before apply                           │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│ PHASE 5: APPROVAL GATE (MANUAL)                                            │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  5.1 Notification Sent                                                      │
│      ├─ Email notification to approver (Sharan / Infrastructure team)       │
│      ├─ Message: "Terraform plan ready for [Hub/UAT/Prod] - Review & Approve"
│      ├─ Link to pipeline execution URL                                      │
│      └─ Link to artifact storage (plan JSON viewable in browser)            │
│                                                                              │
│  5.2 Reviewer Analysis                                                      │
│      ├─ Reviewer opens pipeline URL                                         │
│      ├─ Download & reviews plan artifacts                                   │
│      │  ├─ Open plan JSON in text editor or plan viewer                     │
│      │  ├─ Check resource changes:                                          │
│      │  │  ├─ Additions: Expected? Naming correct? Sizing right?           │
│      │  │  ├─ Modifications: Intentional? Destructive? (e.g., recreation)  │
│      │  │  ├─ Deletions: Correct resources? Not critical?                  │
│      │  │  └─ Security: NSG rules, firewall config, RBAC correct?          │
│      │  │                                                                   │
│      │  ├─ Check reports                                                    │
│      │  │  ├─ tfsec: Any security issues? (encryption, auth, etc.)         │
│      │  │  ├─ tflint: Any warnings or style issues?                        │
│      │  │  └─ Cost estimate: Within budget?                                │
│      │  │                                                                   │
│      │  └─ Compare to version control                                       │
│      │     ├─ PR description: What changes are being made?                  │
│      │     ├─ Changed files: Do they align with plan?                       │
│      │     └─ Approve/Reject reasoning                                      │
│      │                                                                      │
│  5.3 Approval Decision                                                      │
│      │                                                                      │
│      ├─ SCENARIO A: APPROVED ✓                                              │
│      │  ├─ Reviewer clicks "Approve" in pipeline UI                         │
│      │  ├─ Gate passes, pipeline continues to APPLY STAGE                   │
│      │  └─ Notification: "Approval granted, proceeding to apply"            │
│      │                                                                      │
│      ├─ SCENARIO B: REJECTED ✗                                              │
│      │  ├─ Reviewer clicks "Reject" with reason                             │
│      │  ├─ Pipeline stops, no apply executed                                │
│      │  ├─ Notification: "Approval rejected - Review changes needed"        │
│      │  ├─ Developer notified via email/Teams                               │
│      │  └─ Developer must:                                                  │
│      │     ├─ Review rejection comments                                     │
│      │     ├─ Modify code (new commit/push)                                 │
│      │     └─ Trigger pipeline again (or wait for next scheduled run)      │
│      │                                                                      │
│      └─ SCENARIO C: NO ACTION / TIMEOUT                                     │
│         ├─ Approval window expires (e.g., 24 hours)                        │
│         ├─ Plan artifacts deleted (security)                                │
│         └─ Developer must re-run plan stage                                 │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
                                    │
                        (If Approved) │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│ PHASE 6: APPLY STAGE (AUTO, After Approval)                                │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  6.1 Retrieve Plan & State                                                  │
│      ├─ Download plan artifacts from storage                                │
│      │  ├─ hub.tfplan, uat.tfplan, prod.tfplan                              │
│      │  └─ Verify signatures/checksums                                      │
│      │                                                                      │
│      ├─ Re-authenticate to Azure                                            │
│      │  └─ Service Principal credentials from Key Vault (same as plan)      │
│      │                                                                      │
│      └─ Connect to state backend                                            │
│         └─ Download current state files (hub.tfstate, uat.tfstate, etc.)    │
│                                                                              │
│  6.2 Per-Environment Apply Job (Sequential or Parallel per org policy)      │
│      │                                                                      │
│      ├─ For Hub Environment:                                                │
│      │  ├─ cd env/hub                                                       │
│      │  ├─ terraform init (same as plan stage)                              │
│      │  ├─ terraform apply -auto-approve hub.tfplan                        │
│      │  │  ├─ Execute plan without prompting (already approved)             │
│      │  │  ├─ Create resources:                                             │
│      │  │  │  ├─ Azure Resource Group (RG-Hub)                              │
│      │  │  │  ├─ Virtual Network (vnet-hub-eus-001)                         │
│      │  │  │  ├─ Subnets (AzureFirewallSubnet, BastionSubnet, etc.)        │
│      │  │  │  ├─ Network Security Groups + rules                            │
│      │  │  │  ├─ Azure Firewall + public IP + rules                         │
│      │  │  │  ├─ Bastion Host + public IP                                   │
│      │  │  │  ├─ Route Tables + UDRs                                        │
│      │  │  │  └─ Monitoring diagnostics                                     │
│      │  │  │                                                                │
│      │  │  ├─ Update state file (hub.tfstate)                               │
│      │  │  │  ├─ Write resource IDs, properties, metadata                   │
│      │  │  │  ├─ Upload to backend (storage account)                        │
│      │  │  │  └─ Lock released (state lock during apply)                    │
│      │  │  │                                                                │
│      │  │  └─ Output resource information                                   │
│      │  │     ├─ VNet ID, subnet IDs, firewall public IP, etc.              │
│      │  │     └─ Store in pipeline variables for next stage                 │
│      │  │                                                                   │
│      │  ├─ Verify deployment                                                │
│      │  │  ├─ terraform show (display new state)                            │
│      │  │  ├─ Compare state to actual Azure resources (az CLI queries)      │
│      │  │  └─ Confirm all changes applied                                  │
│      │  │                                                                   │
│      │  └─ Log success & output                                             │
│      │     ├─ Terraform outputs: VNet ID, FW IP, Bastion IP, etc.           │
│      │     ├─ Deployment time: X minutes                                    │
│      │     └─ Resource count: 15 resources created                          │
│      │                                                                      │
│      ├─ For UAT Environment: (if approved separately or same approval)      │
│      │  ├─ cd env/uat                                                       │
│      │  ├─ terraform apply -auto-approve uat.tfplan                        │
│      │  └─ Create spoke network + VM resources + outputs                    │
│      │                                                                      │
│      └─ For Prod Environment: (if approved separately or same approval)     │
│         ├─ cd env/prod                                                      │
│         ├─ terraform apply -auto-approve prod.tfplan                       │
│         └─ Create prod spoke network + VM resources + outputs               │
│                                                                              │
│  6.3 Post-Apply Actions                                                     │
│      ├─ Run validation script                                               │
│      │  ├─ az network vnet show (verify VNet created)                       │
│      │  ├─ az network firewall show (verify FW provisioned)                │
│      │  ├─ az vm show (verify VMs running)                                  │
│      │  └─ az network route-table show (verify routing)                    │
│      │                                                                      │
│      ├─ Publish outputs to artifact storage                                 │
│      │  ├─ terraform output -json > hub-output.json                         │
│      │  ├─ terraform output -json > uat-output.json                         │
│      │  └─ terraform output -json > prod-output.json                        │
│      │                                                                      │
│      ├─ Send deployment logs to Log Analytics                               │
│      │  ├─ Apply duration, resource count, errors/warnings                  │
│      │  └─ Query for future drift detection                                 │
│      │                                                                      │
│      └─ Notification (Completion)                                           │
│         ├─ Send email/Teams message: "Deployment SUCCESSFUL"                │
│         ├─ Include deployment summary:                                      │
│         │  ├─ Hub: 15 resources created in X minutes                        │
│         │  ├─ UAT: 10 resources created in Y minutes                        │
│         │  ├─ Prod: 12 resources created in Z minutes                       │
│         │  └─ Total time: (X+Y+Z) minutes                                   │
│         │                                                                   │
│         ├─ Include outputs (useful for manual testing):                      │
│         │  ├─ Bastion public IP                                             │
│         │  ├─ Firewall public IP                                            │
│         │  ├─ VM IDs and private IPs                                        │
│         │  └─ Load balancer IPs (if applicable)                             │
│         │                                                                   │
│         └─ Provide link to outputs JSON in artifact storage                 │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│ PHASE 7: POST-DEPLOYMENT (OPERATIONS)                                      │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  7.1 Day-1 Post-Deploy (Manual)                                             │
│      ├─ Verify connectivity                                                 │
│      │  ├─ SSH to Bastion from internet                                     │
│      │  ├─ SSH from Bastion to spoke VMs                                    │
│      │  ├─ Test HTTP/HTTPS through firewall                                 │
│      │  └─ Confirm database connectivity (if deployed)                      │
│      │                                                                      │
│      ├─ Validate security posture                                           │
│      │  ├─ NSG rules effective & applied                                    │
│      │  ├─ Firewall rules working as expected                               │
│      │  ├─ No unexpected public IPs on spokes                               │
│      │  └─ All diagnostic logging enabled                                   │
│      │                                                                      │
│      ├─ Document deployment (if not auto-generated)                         │
│      │  ├─ Record deployed resource IDs                                     │
│      │  ├─ Record assigned IPs                                              │
│      │  ├─ Record any manual configuration needed                           │
│      │  └─ Create runbook for future reference                              │
│      │                                                                      │
│      └─ Notify stakeholders (production ready)                              │
│         ├─ Ops team: Environments ready for workload deployment             │
│         ├─ Security team: Network configuration review complete             │
│         └─ FinOps team: Cost tracking baseline established                  │
│                                                                              │
│  7.2 Daily Operations (Automated)                                           │
│      ├─ Scheduled Pipeline Job: DRIFT DETECTION (Daily 2:00 AM)            │
│      │  ├─ Trigger: Schedule trigger in azure-pipelines.yml                │
│      │  │  └─ trigger: cron: "0 2 * * *"  (2 AM daily)                     │
│      │  │                                                                   │
│      │  ├─ For each environment (Hub, UAT, Prod):                           │
│      │  │  ├─ cd env/{hub|uat|prod}                                         │
│      │  │  ├─ terraform init (refresh backend)                              │
│      │  │  ├─ terraform plan -detailed-exitcode                             │
│      │  │  │  └─ Exit codes:                                                │
│      │  │  │     ├─ 0 = No changes (no drift)                               │
│      │  │  │     ├─ 1 = Error during plan                                   │
│      │  │  │     └─ 2 = Changes detected (drift found)                      │
│      │  │  │                                                                │
│      │  │  ├─ If exit code == 0:                                            │
│      │  │  │  └─ Log: "No drift detected in {env}"                          │
│      │  │  │                                                                │
│      │  │  └─ If exit code == 2:                                            │
│      │  │     ├─ Log: "DRIFT DETECTED in {env}"                             │
│      │  │     ├─ terraform show (display changes)                           │
│      │  │     ├─ Export plan to JSON                                        │
│      │  │     ├─ Create Azure DevOps Work Item (bug)                        │
│      │  │     │  ├─ Title: "Configuration drift in {env}"                   │
│      │  │     │  ├─ Description: terraform plan output                      │
│      │  │     │  ├─ Assigned to: Infrastructure team                       │
│      │  │     │  ├─ Priority: High                                          │
│      │  │     │  └─ Link to artifact (plan JSON)                            │
│      │  │     │                                                             │
│      │  │     └─ Send Alert                                                 │
│      │  │        ├─ Slack: "@oncall Drift detected in {env}"                │
│      │  │        ├─ Email: Subject "Action Required: Drift Alert"           │
│      │  │        └─ Link to work item                                       │
│      │  │                                                                   │
│      │  └─ Log overall drift status to Log Analytics                        │
│      │     └─ Query: AzureDiagnostics | where type=="DriftDetection"       │
│      │                                                                      │
│      ├─ Scheduled Job: COMPLIANCE CHECK (Daily 3:00 AM)                     │
│      │  ├─ Verify Azure Policy compliance                                   │
│      │  │  ├─ az policy state summarize (per environment)                  │
│      │  │  ├─ Check: All resources have required tags                       │
│      │  │  ├─ Check: All resources in allowed location (East US)            │
│      │  │  ├─ Check: No public IPs on spoke VMs                             │
│      │  │  └─ Report non-compliant resources                                │
│      │  │                                                                   │
│      │  ├─ If non-compliant:                                                │
│      │  │  ├─ Trigger policy remediation (auto-apply tags, etc.)            │
│      │  │  └─ Create work item for manual remediation if needed             │
│      │  │                                                                   │
│      │  └─ Generate compliance report (weekly)                              │
│      │     ├─ % compliance per environment                                  │
│      │     ├─ Violations by type (tag, location, security)                  │
│      │     └─ Remediation status                                            │
│      │                                                                      │
│      ├─ Scheduled Job: SECURITY SCAN (Weekly, Sundays 3:00 AM)              │
│      │  ├─ Run tfsec on current infrastructure                              │
│      │  │  ├─ Export state to JSON (terraform show -json)                   │
│      │  │  ├─ Analyze: Encryption status, auth methods, network exposure    │
│      │  │  └─ Generate report: Security findings (high/medium/low)          │
│      │  │                                                                   │
│      │  ├─ Run Azure Security Center recommendations                        │
│      │  │  ├─ Query ASC API: az security auto-provisioning-setting         │
│      │  │  ├─ Alert on: Unpatched VMs, disabled firewalls, open ports       │
│      │  │  └─ Create work items for critical findings                       │
│      │  │                                                                   │
│      │  └─ Generate security report (weekly)                                │
│      │     ├─ Vulnerabilities by environment                                │
│      │     ├─ Remediation guide per finding                                 │
│      │     └─ Risk score (overall)                                          │
│      │                                                                      │
│      └─ Scheduled Job: COST OPTIMIZATION (Monthly, 1st day)                │
│         ├─ Query: Resource utilization (CPU, memory, disk)                  │
│         │  ├─ Identify underutilized VMs (< 20% CPU)                        │
│         │  ├─ Recommend right-sizing (e.g., B2s → B1s)                      │
│         │  └─ Estimate savings (per month)                                  │
│         │                                                                   │
│         ├─ Generate cost report                                             │
│         │  ├─ Actual cost vs budget (per environment)                       │
│         │  ├─ Cost per resource type                                        │
│         │  ├─ Recommendations for optimization                              │
│         │  └─ Projected annual cost                                         │
│         │                                                                   │
│         └─ Create optimization task (if savings > 10%)                      │
│            └─ Assigned to: FinOps / Infrastructure team                     │
│                                                                              │
│  7.3 Ongoing Management                                                     │
│      ├─ Monitoring & Alerting                                               │
│      │  ├─ Log Analytics: Application, firewall, NSG logs ingested          │
│      │  ├─ Azure Monitor: Metrics (CPU, memory, network)                    │
│      │  ├─ Alerts: On anomalies (e.g., failed SSH attempts, high FW denies) │
│      │  └─ Dashboards: Custom KQL queries for operations team               │
│      │                                                                      │
│      ├─ Backups & Disaster Recovery                                         │
│      │  ├─ Azure Backup: VM snapshots (daily)                               │
│      │  ├─ State backup: Terraform state versioning in storage              │
│      │  ├─ Disaster recovery plan:                                          │
│      │  │  ├─ RTO: 2 hours (time to restore)                                │
│      │  │  ├─ RPO: 24 hours (data loss acceptable)                          │
│      │  │  └─ Process: Restore from backup, re-apply Terraform              │
│      │  └─ Test DR quarterly                                                │
│      │                                                                      │
│      └─ Change Management                                                   │
│         ├─ All infrastructure changes via Git + Terraform + Pipeline        │
│         ├─ No manual Azure Portal changes (enforce via policy)              │
│         ├─ Change log: Git history + Terraform state history                │
│         └─ Rollback: Revert commit + re-apply Terraform to roll back       │
│                                                                              │
│  7.4 Periodic Reviews (Quarterly)                                           │
│      ├─ Architecture review: Are we meeting requirements?                   │
│      ├─ Security review: Any new compliance requirements?                   │
│      ├─ Cost review: Any cost optimization opportunities?                   │
│      ├─ Performance review: Any scaling needs?                              │
│      └─ Update documentation & runbooks                                     │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Phase Diagram (High-Level Summary)

```
PHASE 1: PLANNING
    │
    ├─ Requirements gathering
    ├─ Architecture design
    ├─ Resource planning
    └─ Pre-requisites setup
         │
         ▼
PHASE 2: DEVELOPMENT
    │
    ├─ Code written (feature branches)
    ├─ Pre-commit checks
    ├─ Code review (PR)
    └─ Merge to main
         │
         ▼
PHASE 3: GIT EVENT
    │
    ├─ Push to main triggers webhook
    └─ Change detection (git diff)
         │
         ▼
PHASE 4: PLANNING PIPELINE (AUTO)
    │
    ├─ Setup & authenticate
    ├─ terraform plan (per env)
    ├─ Security scan (tfsec)
    ├─ Publish plan artifacts
    └─ **PAUSE** awaiting approval
         │
         ▼
PHASE 5: APPROVAL (MANUAL)
    │
    ├─ Approver reviews plan
    ├─ Checks: Changes OK? Security OK? Cost OK?
    ├─ Decision: Approve / Reject
    │
    ├─ IF APPROVED ──────────────────┐
    │ (continue to apply)            │
    │                                │
    └────────────────────────────────┤
                                     ▼
PHASE 6: DEPLOY PIPELINE (AUTO)
    │
    ├─ Download plan artifact
    ├─ terraform apply (per env)
    ├─ Verify resources deployed
    ├─ Publish outputs
    └─ Send notification (DEPLOYMENT SUCCESS)
         │
         ▼
PHASE 7: OPERATIONS (ONGOING)
    │
    ├─ Day-1: Verify connectivity & security
    ├─ Daily: Drift detection (scheduled job)
    ├─ Weekly: Security scan & compliance check
    ├─ Monthly: Cost optimization review
    ├─ Quarterly: Architecture & performance review
    └─ Continuous: Monitoring, alerting, backups
```

---

## 3. Pipeline Stage Details

### 3.1 Plan Stage Workflow (Detail)

```
PLAN STAGE
│
├─ CHECKOUT & AUTH
│  ├─ git clone / checkout code
│  ├─ Install tools (terraform, az cli, tfsec, tflint)
│  └─ az login (service principal from Key Vault)
│
├─ PER-ENVIRONMENT JOBS (Parallel)
│  │
│  ├─ JOB: Plan-Hub
│  │  ├─ cd env/hub
│  │  ├─ terraform init
│  │  ├─ terraform validate
│  │  ├─ terraform plan -out=hub.tfplan
│  │  ├─ tfsec + tflint
│  │  └─ PublishBuildArtifacts (hub.tfplan + reports)
│  │
│  ├─ JOB: Plan-UAT
│  │  ├─ cd env/uat
│  │  ├─ terraform init
│  │  ├─ terraform validate
│  │  ├─ terraform plan -out=uat.tfplan
│  │  ├─ tfsec + tflint
│  │  └─ PublishBuildArtifacts (uat.tfplan + reports)
│  │
│  └─ JOB: Plan-Prod
│     ├─ cd env/prod
│     ├─ terraform init
│     ├─ terraform validate
│     ├─ terraform plan -out=prod.tfplan
│     ├─ tfsec + tflint
│     └─ PublishBuildArtifacts (prod.tfplan + reports)
│
└─ SUMMARY & GATE
   ├─ Log summary (3 envs planned, X resources total)
   └─ **Manual Approval Required Before Apply**
```

### 3.2 Approval Gate Workflow (Detail)

```
APPROVAL GATE
│
├─ EMAIL NOTIFICATION
│  ├─ Sent to: Sharan (approver)
│  ├─ Subject: "Review Required: Terraform Plan - Hub, UAT, Prod"
│  ├─ Content: 
│  │  ├─ Environments: Hub, UAT, Prod
│  │  ├─ Summary: 32 resources to create/modify
│  │  ├─ Changes:
│  │  │  ├─ Hub: 15 create (VNet, Firewall, Bastion, NSGs)
│  │  │  ├─ UAT: 10 create (VNet, 2 VMs, NSGs, LB)
│  │  │  └─ Prod: 12 create + 1 update (VNet, 2 VMs, NSGs, LB, policy update)
│  │  ├─ Security scan: 0 HIGH, 2 MEDIUM, 3 LOW
│  │  ├─ Cost estimate: $1,250/month increase
│  │  └─ Action: Review plan & approve/reject
│  │       Link to pipeline: https://dev.azure.com/...
│  │
│  └─ Approver clicks link → Opens Pipeline UI
│
├─ REVIEWER OPENS PIPELINE
│  ├─ Clicks on "Plan" stage
│  ├─ Views logs:
│  │  ├─ terraform plan output (resources listed)
│  │  ├─ tfsec report (security findings)
│  │  ├─ tflint report (style/best practice warnings)
│  │  └─ terraform cost estimation (if using costimation tool)
│  │
│  ├─ Downloads artifacts
│  │  ├─ hub.tfplan (binary, view via terraform show)
│  │  ├─ hub-plan.json (readable, view in editor)
│  │  ├─ tfsec-report.json (security scan)
│  │  └─ tflint-report.json (linting)
│  │
│  └─ Reviews key points
│     ├─ Resource naming: Matches convention? ✓
│     ├─ Resource sizing: Appropriate for UAT/Prod? ✓
│     ├─ Security: NSG rules correct? Firewall rules? ✓
│     ├─ Network: VNet peering correct? Routing? ✓
│     ├─ Cost: Budget approved? $1,250 OK? ✓
│     └─ Decision: APPROVE ✓ or REJECT ✗
│
└─ APPROVAL GATE DECISION
   │
   ├─ PATH A: APPROVE
   │  ├─ Reviewer clicks "Approve" button
   │  ├─ Gate passes → Continue to Apply Stage
   │  ├─ Notification: "Approved, proceeding to apply"
   │  └─ Developer notified: "Your deployment approved"
   │
   ├─ PATH B: REJECT
   │  ├─ Reviewer clicks "Reject" + reason
   │  ├─ Gate fails → Apply stage skipped
   │  ├─ Notification: "Rejected - See comments"
   │  ├─ Developer notified via email/Teams:
   │  │  └─ "Your plan was rejected. Reason: ..."
   │  │     "Please review and resubmit"
   │  │
   │  └─ Developer action:
   │     ├─ Review rejection comments
   │     ├─ Modify code in feature branch
   │     ├─ Commit & push (new push triggers plan again)
   │     └─ Re-request review
   │
   └─ PATH C: TIMEOUT
      ├─ No action for 24 hours
      ├─ Plan artifact expires (security)
      └─ Developer must re-trigger plan stage
         └─ git push (new commit or force push)
```

### 3.3 Apply Stage Workflow (Detail)

```
APPLY STAGE (After Approval)
│
├─ CHECKOUT & AUTH (same as plan)
│  ├─ Download artifacts (hub.tfplan, uat.tfplan, prod.tfplan)
│  ├─ Verify artifact signatures
│  └─ az login (service principal)
│
├─ PER-ENVIRONMENT APPLY JOBS
│  │ (Sequential or parallel per org policy)
│  │
│  ├─ JOB: Apply-Hub
│  │  ├─ cd env/hub
│  │  ├─ terraform init
│  │  ├─ terraform apply -auto-approve hub.tfplan
│  │  │  │
│  │  │  ├─ Create resources:
│  │  │  │  ├─ Resource Group: rg-hub-eus-001
│  │  │  │  ├─ VNet: vnet-hub-eus-001 (10.0.0.0/16)
│  │  │  │  ├─ Subnets (4 subnets)
│  │  │  │  ├─ NSG: nsg-hub-eus-001 + rules
│  │  │  │  ├─ Public IP (x2): firewall IP + bastion IP
│  │  │  │  ├─ Firewall: fw-eus-001 (in AzureFirewallSubnet)
│  │  │  │  ├─ Bastion: bastion-eus-001 (in BastionSubnet)
│  │  │  │  ├─ Route Table: rt-hub-eus-001 + UDRs
│  │  │  │  ├─ Diagnostic settings (NSG flow logs, FW logs → Log Analytics)
│  │  │  │  └─ Tags applied (managed_by=terraform, environment=hub, etc.)
│  │  │  │
│  │  │  ├─ Resource provisioning time: ~15 minutes
│  │  │  │  (Firewall takes longest, others parallel)
│  │  │  │
│  │  │  ├─ Update state file (hub.tfstate)
│  │  │  │  ├─ Write all resource IDs, properties
│  │  │  │  ├─ Upload to backend (state storage account)
│  │  │  │  ├─ Release state lock
│  │  │  │  └─ Versioning (preserve old states for rollback)
│  │  │  │
│  │  │  └─ Output deployment info:
│  │  │     ├─ Resource Group ID
│  │  │     ├─ VNet ID + Subnets IDs
│  │  │     ├─ Firewall public IP (e.g., 20.XX.XX.XX)
│  │  │     ├─ Bastion public IP (e.g., 20.YY.YY.YY)
│  │  │     ├─ Firewall resource ID (for RBAC)
│  │  │     └─ Bastion resource ID (for access config)
│  │  │
│  │  ├─ Verification:
│  │  │  ├─ terraform show (display state)
│  │  │  ├─ az resource group show (verify RG)
│  │  │  ├─ az network vnet show (verify VNet)
│  │  │  └─ az network firewall show (verify FW)
│  │  │
│  │  └─ Publish outputs:
│  │     ├─ terraform output -json > hub-outputs.json
│  │     ├─ Upload to artifact storage (for reference)
│  │     └─ Export to pipeline variables (for UAT/Prod peering setup)
│  │
│  ├─ JOB: Apply-UAT
│  │  ├─ cd env/uat
│  │  ├─ terraform init
│  │  ├─ terraform apply -auto-approve uat.tfplan
│  │  │  │
│  │  │  ├─ Create resources:
│  │  │  │  ├─ Resource Group: rg-uat-eus-001
│  │  │  │  ├─ VNet: vnet-spoke-uat-eus-001 (10.1.0.0/16)
│  │  │  │  ├─ Subnets (3: app, data, mgmt)
│  │  │  │  ├─ NSG: nsg-spoke-uat-eus-001 + rules
│  │  │  │  ├─ VMs (2 instances):
│  │  │  │  │  ├─ vm-app-uat-01 (10.1.1.10)
│  │  │  │  │  └─ vm-app-uat-02 (10.1.1.11)
│  │  │  │  ├─ Network Interfaces (x2 for VMs)
│  │  │  │  ├─ Public IPs: None (access via Bastion)
│  │  │  │  ├─ Load Balancer (optional): lb-uat-eus-001
│  │  │  │  ├─ Route Table: rt-spoke-uat-eus-001 + UDR (0.0.0.0/0 → FW)
│  │  │  │  ├─ VNet Peering: peer-hub-to-uat (connect to hub)
│  │  │  │  ├─ Diagnostic settings
│  │  │  │  └─ Tags applied
│  │  │  │
│  │  │  ├─ Provisioning time: ~10 minutes (VMs are slowest)
│  │  │  │
│  │  │  └─ Output deployment info:
│  │  │     ├─ VNet ID + Subnet IDs
│  │  │     ├─ VM IDs + Private IPs (10.1.1.10, 10.1.1.11)
│  │  │     ├─ Load Balancer IP (if deployed)
│  │  │     ├─ NSG ID
│  │  │     └─ Route Table ID
│  │  │
│  │  └─ Post-create configuration:
│  │     ├─ Verify VNet peering created (hub↔uat)
│  │     ├─ Verify routing table applied (0.0.0.0/0 → firewall)
│  │     ├─ Verify NSG rules applied (allow SSH from bastion only)
│  │     └─ Test connectivity (from bastion to VM via SSH)
│  │
│  └─ JOB: Apply-Prod
│     ├─ cd env/prod
│     ├─ terraform apply -auto-approve prod.tfplan
│     │  (Similar to UAT, but with stricter NSG rules, larger VM SKU)
│     │
│     └─ Prod-specific:
│        ├─ Standard_D2s_v3 VMs (larger than UAT B2s)
│        ├─ 2 VMs (higher availability requirement)
│        ├─ NSG rules more restrictive (no direct RDP, SSH only for limited ops)
│        ├─ Load Balancer with health checks
│        ├─ Azure Backup enabled (daily snapshots)
│        └─ Enhanced monitoring (more granular Log Analytics)
│
└─ POST-APPLY SUMMARY
   ├─ Total deployment time: 35-45 minutes
   │  ├─ Hub: 15 min
   │  ├─ UAT: 10 min
   │  └─ Prod: 15 min
   │
   ├─ Resources deployed:
   │  ├─ Hub: 15 resources
   │  ├─ UAT: 10 resources
   │  ├─ Prod: 12 resources
   │  └─ Total: 37 resources
   │
   ├─ Deployment notification sent:
   │  ├─ Recipients: Infrastructure team, DevOps, FinOps
   │  ├─ Status: SUCCESS ✓
   │  ├─ Subject: "Infrastructure Deployment Complete - All Environments"
   │  ├─ Content:
   │  │  ├─ Hub deployed successfully (15 resources)
   │  │  ├─ UAT spoke deployed successfully (10 resources)
   │  │  ├─ Prod spoke deployed successfully (12 resources)
   │  │  ├─ Key outputs:
   │  │  │  ├─ Firewall public IP: 20.XX.XX.XX
   │  │  │  ├─ Bastion public IP: 20.YY.YY.YY
   │  │  │  ├─ UAT VM IPs: 10.1.1.10, 10.1.1.11
   │  │  │  ├─ Prod VM IPs: 10.2.1.10, 10.2.1.11
   │  │  │  └─ Load Balancers: UAT (10.1.1.250), Prod (10.2.1.250)
   │  │  │
   │  │  └─ Next steps:
   │  │     ├─ Connect to Bastion (SSH to public IP)
   │  │     ├─ Access application VMs from Bastion
   │  │     ├─ Configure application workloads
   │  │     ├─ Run security validation
   │  │     └─ Test disaster recovery (backup restore)
   │  │
   │  └─ Link to deployment logs: https://dev.azure.com/...
   │
   └─ **DEPLOYMENT PIPELINE COMPLETE**
      All environments ready for operations
```

---

## 4. Decision Tree for Approver

```
APPROVER DECISION TREE
│
├─ Review terraform plan output
│  │
│  └─ Question 1: "Are the resources being created as expected?"
│     ├─ NO → Reject (reason: "Unexpected resource creation")
│     │       Developer will investigate & resubmit
│     │
│     └─ YES ↓
│        │
│        └─ Question 2: "Are any CRITICAL resources being destroyed?"
│           ├─ YES → Reject (reason: "Destructive change - review required")
│           │       Developer must clarify intent
│           │
│           └─ NO ↓
│              │
│              └─ Question 3: "Security checks OK?" (tfsec, tflint)
│                 ├─ HIGH severity issues found → Reject (reason: "Security issues")
│                 │       Developer must fix security findings
│                 │
│                 └─ NO HIGH issues ↓
│                    │
│                    └─ Question 4: "Cost within budget?" (estimate check)
│                       ├─ > 20% increase → Reject (reason: "Cost increase needs approval")
│                       │       Escalate to finance
│                       │
│                       └─ Within budget ↓
│                          │
│                          └─ Question 5: "Network configuration correct?"
│                             ├─ NSG rules appropriate? ✓
│                             ├─ Firewall rules sound? ✓
│                             ├─ Routing correct? ✓
│                             ├─ Peering configured properly? ✓
│                             │
│                             └─ ALL YES ↓
│                                │
│                                └─ **APPROVE** ✓
│                                   Proceed to Apply Stage
```

---

## 5. Error Handling & Recovery

```
ERROR SCENARIOS
│
├─ SCENARIO 1: Terraform Plan Fails
│  ├─ Cause: Syntax error, missing variable, resource conflict
│  ├─ Detection: Exit code 1 in plan stage
│  ├─ Pipeline action: Stage fails, no artifact published
│  ├─ Notification: Developer notified (email)
│  │  └─ Error log: terraform plan output (show error)
│  │
│  └─ Recovery:
│     ├─ Developer reviews error
│     ├─ Fixes code (Terraform file)
│     ├─ Pushes fix (new commit)
│     └─ Pipeline re-runs (triggered by push)
│
├─ SCENARIO 2: Security Scan Fails (tfsec HIGH severity)
│  ├─ Cause: Unencrypted storage, public IP exposure, etc.
│  ├─ Detection: tfsec report shows HIGH findings
│  ├─ Pipeline action: Plan stage completes, artifact marked "Review Before Approval"
│  ├─ Notification: Approver sees security findings
│  │
│  └─ Recovery:
│     ├─ Approver rejects (reason: "Security findings")
│     ├─ Developer reviews tfsec report
│     ├─ Developer fixes security issue (e.g., add encryption)
│     ├─ Pushes fix
│     └─ Re-run plan (security checks pass)
│
├─ SCENARIO 3: Approval Timeout / Expires
│  ├─ Cause: Approver unavailable >24 hours
│  ├─ Detection: Pipeline holds approval gate, timeout triggers
│  ├─ Pipeline action: Plan artifact deleted (security)
│  ├─ Notification: Developer notified
│  │
│  └─ Recovery:
│     ├─ Developer re-triggers plan (new push or manual trigger)
│     └─ Back to Plan stage
│
├─ SCENARIO 4: Apply Fails (Resource Creation Error)
│  ├─ Cause: Quota exceeded, API error, invalid config
│  ├─ Detection: Exit code 1 in apply stage
│  ├─ Pipeline action: Apply stage fails, partial state may be saved
│  ├─ Notification: Team alerted immediately (critical)
│  │
│  └─ Recovery:
│     ├─ Investigate error (terraform logs)
│     ├─ If quota issue: Request quota increase from Azure
│     ├─ If config issue: Fix in code, re-apply
│     ├─ If partial state: Manual cleanup (destroy half-created resources)
│     └─ Re-run apply with corrected state
│
├─ SCENARIO 5: Drift Detected (Resources Modified Outside Terraform)
│  ├─ Cause: Manual Azure Portal change, script ran, policy enforcement
│  ├─ Detection: Daily drift detection job finds 2 exit code
│  ├─ Notification: Work item created, Slack alert sent
│  │
│  └─ Recovery (Options):
│     ├─ Option A: Import resource into Terraform state (if intentional)
│     │  ├─ terraform import azurerm_X.Y resource_id
│     │  ├─ Update Terraform code to match
│     │  ├─ Commit & push (update state)
│     │  └─ Future runs will track this resource
│     │
│     ├─ Option B: Destroy manual change (if unintentional)
│     │  ├─ Identify manual change (from Azure activity log)
│     │  ├─ Revert or delete in Azure Portal
│     │  ├─ Confirm drift detection clears
│     │  └─ Investigate how change happened (audit)
│     │
│     └─ Option C: Update Terraform to match reality
│        ├─ If reality is correct: Update .tf files
│        ├─ If Terraform is correct: Revert reality to match TF
│        └─ Document decision in commit message
│
└─ SCENARIO 6: Rollback Required (Deployment Caused Issues)
   ├─ Cause: Deployed config broke production app
   ├─ Detection: Monitoring alerts, manual discovery
   ├─ Action: Emergency rollback required
   │
   └─ Recovery:
      ├─ Option A: Revert Terraform code
      │  ├─ git revert HEAD (or git reset --hard)
      │  ├─ terraform apply (will destroy/recreate to match old state)
      │  ├─ Time: 15-30 minutes (risk of state conflicts)
      │  └─ Best if recent deployment
      │
      ├─ Option B: Restore from backup
      │  ├─ Snapshot VM state from before deployment
      │  ├─ Restore configuration from backup
      │  ├─ Time: 10-20 minutes
      │  └─ Requires backup to exist
      │
      └─ Option C: Terraform destroy + re-create (nuclear option)
         ├─ terraform destroy -auto-approve (delete all)
         ├─ terraform apply -auto-approve (recreate from last known good state)
         ├─ Time: 45+ minutes
         └─ Use only if other options fail
```

---

## 6. Communication Plan

### 6.1 Notifications & Alerting

| Stage | Event | Recipient | Method | Content |
|-------|-------|-----------|--------|---------|
| Plan | Plan complete | Approver | Email | "Plan ready, 32 resources affected" + link |
| Approval | Rejected | Developer | Email/Teams | "Plan rejected - See comments" + reason |
| Approval | Approved | Ops Team | Email/Slack | "Plan approved, deploying now" |
| Apply | Started | Team | Slack | "Deployment in progress..." |
| Apply | Success | Team | Email/Slack | "Deployment SUCCESS - All environments live" + outputs |
| Apply | Failed | Team | Email/PagerDuty | "ALERT: Deployment FAILED - Immediate action required" |
| Drift | Detected | Ops Team | Slack/Email | "Drift detected in Prod - Work item created" |
| Compliance | Failed | Team | Email/Slack | "Compliance check failed - 3 violations" |

### 6.2 Incident Response (if Apply Fails)

```
INCIDENT RESPONSE FLOWCHART

Apply fails → Immediate Actions:
  │
  ├─ Page on-call engineer (PagerDuty)
  ├─ Post incident in Slack (#incidents channel)
  ├─ Create incident ticket (with timestamp, error, severity)
  │
  ├─ INVESTIGATE (first 5 min):
  │  ├─ Terraform apply logs (what failed?)
  │  ├─ Azure diagnostics (resource errors?)
  │  ├─ Activity log (what was attempted?)
  │  └─ Previous state (what was working before?)
  │
  ├─ TRIAGE (next 5 min):
  │  ├─ Is it critical? (e.g., broke prod app)
  │  │  └─ YES → IMMEDIATE ROLLBACK
  │  │  └─ NO → INVESTIGATE root cause
  │  │
  │  └─ Can we fix quickly? (<15 min)
  │     └─ YES → Fix & re-apply
  │     └─ NO → Consider rollback
  │
  ├─ REMEDIATE (10-30 min):
  │  ├─ Apply fix / rollback / manual workaround
  │  └─ Verify system recovered
  │
  ├─ DOCUMENT:
  │  ├─ What happened (root cause)
  │  ├─ How it was fixed
  │  ├─ How to prevent next time
  │  └─ Ticket for follow-up (post-incident review)
  │
  └─ CLOSE:
     ├─ Update incident ticket
     ├─ Notify stakeholders (all clear)
     └─ Schedule post-mortem (if critical)
```

---

## 7. Terraform State Transitions

```
STATE TRANSITIONS THROUGHOUT PIPELINE

Initial State (Before Plan):
┌─────────────────────────────────────┐
│ State Version: v1 (e.g., hub.tfstate)        
│ Resources: 0                         │
│ Last modified: 3 days ago            │
│ Deployed: 0 resources in Azure       │
└─────────────────────────────────────┘
             │
             ▼
Plan Stage:
┌─────────────────────────────────────┐
│ Generate: hub.tfplan (artifact)      │
│ State: UNCHANGED (read-only during plan) │
│ Actions: None (plan stage doesn't modify) │
└─────────────────────────────────────┘
             │
             ▼
Approval:
┌─────────────────────────────────────┐
│ Plan artifact locked (can't modify)  │
│ Waiting for approval...              │
└─────────────────────────────────────┘
             │
             ▼
Apply Stage:
┌─────────────────────────────────────┐
│ Apply hub.tfplan                     │
│ Lock acquired on state file          │
│ Create resources in Azure            │
│ Update state file with resource IDs  │
│ Upload state to backend              │
│ Lock released                        │
└─────────────────────────────────────┘
             │
             ▼
Post-Apply State (After Successful Apply):
┌─────────────────────────────────────┐
│ State Version: v2 (hub.tfstate)              
│ Resources: 15                        │
│ Last modified: NOW (just applied)    │
│ Deployed: 15 resources in Azure      │
│                                      │
│ Resource mapping:                    │
│ azurerm_resource_group.hub           │
│   → /subscriptions/XXX/resourceGroups/rg-hub-eus-001 │
│ azurerm_virtual_network.hub          │
│   → /subscriptions/XXX/resourceGroups/rg-hub-eus-001/providers/Microsoft.Network/virtualNetworks/vnet-hub-eus-001 │
│ ... (13 more resources)              │
└─────────────────────────────────────┘
```

---

**Document Version**: 1.0  
**Last Updated**: March 31, 2026  
**Project Manager**: Infrastructure Team  
**Approval Flow Owner**: DevOps Lead
