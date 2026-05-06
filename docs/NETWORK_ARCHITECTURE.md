# Network Architecture Documentation

**Version**: 1.0  
**Date**: March 2026  
**Project**: IaC Demo - Hub/Spoke Network Design  
**Purpose**: Detailed network topology, subnetting, routing, security rules, and traffic flow  

---

## 1. Network Design Overview

This document provides comprehensive details on the hub-spoke network topology deployed on Azure. The design emphasizes:
- **Centralized network control** (hub)
- **Workload isolation** (spokes)
- **Zero-trust security** (firewall enforcement, NSG filtering)
- **Secure connectivity** (bastion, forced tunneling)
- **Audit-ready** (NSG flow logs, firewall logging)

---

## 2. Network Topology Diagram

```
╔════════════════════════════════════════════════════════════════════════════╗
║                         NETWORK TOPOLOGY                                   ║
╚════════════════════════════════════════════════════════════════════════════╝

                              INTERNET (0.0.0.0/0)
                                    │
                                    ▼
                    ┌───────────────────────────────┐
                    │   PUBLIC IP (Firewall NAT)    │
                    │   e.g., 20.XX.XX.XX           │
                    └──────────┬────────────────────┘
                               │
                    ┌──────────▼──────────┐
                    │  AZURE FIREWALL     │
                    │  (Hub - 10.0.1/24)  │
                    │                     │
                    │ App Rules:          │
                    │ • HTTP/HTTPS        │
                    │ • SSH (mgmt)        │
                    │ • Custom protocols  │
                    │                     │
                    │ Network Rules:      │
                    │ • Port filtering    │
                    │ • Protocol control  │
                    │ • Threat intel      │
                    └───┬────────┬────────┘
                        │        │
          ┌─────────────┼────────┼──────────────┐
          │             │        │              │
        UDR           UDR      UDR            Direct
      0.0.0/0        Route    Route           Route
          │             │        │              │
    ┌─────▼────┐  ┌────▼─────┐  ┌────▼─────┐  ┌──▼──────┐
    │   HUB    │  │   VNET   │  │   VNET   │  │ PEERING │
    │ VNET     │  │   UAT    │  │   PROD   │  │ (Hub←→) │
    │10.0.0/16 │  │10.1.0/16 │  │10.2.0/16 │  └─────────┘
    │          │  │          │  │          │
    ├──────────┤  ├──────────┤  ├──────────┤
    │Subnets:  │  │Subnets:  │  │Subnets:  │
    │          │  │          │  │          │
    │• 10.0.1  │  │• 10.1.1  │  │• 10.2.1  │
    │  FW      │  │  App     │  │  App     │
    │          │  │          │  │          │
    │• 10.0.2  │  │• 10.1.2  │  │• 10.2.2  │
    │  Bastion │  │  Data    │  │  Data    │
    │          │  │          │  │          │
    │• 10.0.3  │  │• 10.1.3  │  │• 10.2.3  │
    │  GW      │  │  Mgmt    │  │  Mgmt    │
    │          │  │          │  │          │
    │• 10.0.4  │  └──────────┘  └──────────┘
    │  Mgmt    │        │              │
    │          │        │              │
    └──────────┘   ┌────▼────┐   ┌────▼────┐
         │         │   NSG   │   │   NSG   │
         │         │ (UAT)   │   │ (Prod)  │
         │         └────┬────┘   └────┬────┘
         │              │             │
         │         ┌────▼────┐   ┌────▼────┐
         │         │   VMs   │   │   VMs   │
         │         │(App Tier)   │(App Tier)
         │         │ 10.1.1.x    │ 10.2.1.x
         │         └─────────┘   └─────────┘
         │
    ┌────▼──────────┐
    │  Bastion Host │
    │ (Jump Server) │
    │  10.0.2.x     │
    │  Public IP    │
    │  (optional)   │
    └───────────────┘

PEERING CONNECTIONS:
├─ Hub ↔ UAT: Enabled (allow_forwarded_traffic=true, use_remote_gateways=true)
├─ Hub ↔ Prod: Enabled (allow_forwarded_traffic=true, use_remote_gateways=true)
└─ UAT ↔ Prod: Optional (can be disabled for strict environment isolation)
```

---

## 3. Subnet Design & Addressing

### 3.1 Hub Subnet Allocation

| Subnet Name | CIDR Block | Size | Purpose | Resources |
|-------------|-----------|------|---------|-----------|
| AzureFirewallSubnet | 10.0.1.0/24 | 256 IPs | Azure Firewall | Firewall (required by Azure) |
| BastionSubnet | 10.0.2.0/24 | 256 IPs | Bastion Host | Bastion, NSG |
| GatewaySubnet | 10.0.3.0/24 | 256 IPs | VPN/ExpressRoute | VPN gateway (reserved) |
| ManagementSubnet | 10.0.4.0/24 | 256 IPs | Hub Management | Jump boxes, monitoring agents |

**Hub VNet Capacity**: `10.0.0.0/16` = 65,536 IPs total
**Hub Utilization**: ~5% (1,024 IPs / 65,536)
**Future Growth**: 15 additional subnets available

### 3.2 UAT Spoke Subnet Allocation

| Subnet Name | CIDR Block | Size | Purpose | Resources |
|-------------|-----------|------|---------|-----------|
| ApplicationSubnet | 10.1.1.0/24 | 256 IPs | App servers | VMs, LB frontend |
| DataSubnet | 10.1.2.0/24 | 256 IPs | Databases | SQL Server, Cache |
| ManagementSubnet | 10.1.3.0/24 | 256 IPs | Mgmt/Ops | Monitoring, backup |

**UAT VNet Capacity**: `10.1.0.0/16` = 65,536 IPs total
**UAT Utilization**: ~2% (768 IPs / 65,536)

### 3.3 Prod Spoke Subnet Allocation

| Subnet Name | CIDR Block | Size | Purpose | Resources |
|-------------|-----------|------|---------|-----------|
| ApplicationSubnet | 10.2.1.0/24 | 256 IPs | App servers | VMs, LB frontend |
| DataSubnet | 10.2.2.0/24 | 256 IPs | Databases | SQL Server, Cache |
| ManagementSubnet | 10.2.3.0/24 | 256 IPs | Mgmt/Ops | Monitoring, backup |

**Prod VNet Capacity**: `10.2.0.0/16` = 65,536 IPs total
**Prod Utilization**: ~2% (768 IPs / 65,536)

### 3.4 Reserved IP Ranges (Future Use)

```
10.3.0.0/16 - Reserved for future UAT expansion
10.4.0.0/16 - Reserved for future Prod expansion
10.5.0.0/16 - Reserved for future DR/Disaster region
...
10.255.0.0/16 - Reserved
```

---

## 4. Routing Architecture

### 4.1 Hub Route Table

**Route Table Name**: `rt-hub-eus-001`
**Associated Subnets**: AzureFirewallSubnet, ManagementSubnet, GatewaySubnet

| Destination | Next Hop | Purpose |
|-------------|----------|---------|
| 10.0.0.0/16 | Local | Hub VNet local traffic (direct) |
| 10.1.0.0/16 | Peering | UAT Spoke via VNet Peering |
| 10.2.0.0/16 | Peering | Prod Spoke via VNet Peering |
| 0.0.0.0/0 | Firewall | Internet traffic (hub only if needed) |

**Notes**:
- No UDR (User Defined Route) forcing hub traffic via firewall (unnecessary, firewall in same VNet)
- Peering routes are auto-created when peering enabled
- Internet routes via firewall optional for hub (typically not needed)

### 4.2 UAT Spoke Route Table

**Route Table Name**: `rt-spoke-uat-eus-001`
**Associated Subnets**: ApplicationSubnet, DataSubnet, ManagementSubnet

| Destination | Next Hop | Purpose |
|-------------|----------|---------|
| 10.1.0.0/16 | Local | UAT VNet local traffic (direct) |
| 10.0.0.0/16 | Peering | Hub via VNet Peering |
| 10.2.0.0/16 | Peering | Prod Spoke via VNet Peering (optional) |
| 0.0.0.0/0 | Firewall | All Internet traffic forced through FW |

**Force Tunneling**:
- UDR `0.0.0.0/0` → Firewall public IP ensures all egress through FW
- Incoming: NSG filtering on ingress rules
- Outbound: NAT via firewall public IP (all traffic appears from FW IP)

### 4.3 Prod Spoke Route Table

**Route Table Name**: `rt-spoke-prod-eus-001`
**Associated Subnets**: ApplicationSubnet, DataSubnet, ManagementSubnet

| Destination | Next Hop | Purpose |
|-------------|----------|---------|
| 10.2.0.0/16 | Local | Prod VNet local traffic (direct) |
| 10.0.0.0/16 | Peering | Hub via VNet Peering |
| 10.1.0.0/16 | Peering | UAT Spoke via VNet Peering (optional) |
| 0.0.0.0/0 | Firewall | All Internet traffic forced through FW |

**Force Tunneling**: Same as UAT (all egress via firewall)

### 4.4 Route Priority & BGP

- **Static Routes**: UDRs have highest priority
- **Peering Routes**: Auto-created, lower priority than explicit UDRs
- **System Routes**: Local routes always most specific (10.x.0.0/16)
- **Longest Prefix Match**: Routes with /32 or /30 evaluated first

---

## 5. Network Security Groups (NSGs)

### 5.1 Hub NSG

**NSG Name**: `nsg-hub-eus-001`
**Associated Subnets**: BastionSubnet, ManagementSubnet

#### Inbound Rules

| Priority | Name | Source | Dest Port | Protocol | Action | Purpose |
|----------|------|--------|-----------|----------|--------|---------|
| 100 | AllowSSHFromInternet | Internet (0.0.0.0/0) | 22 | TCP | Allow | SSH to Bastion (tighten in prod) |
| 110 | AllowRDPFromInternet | Internet (0.0.0.0/0) | 3389 | TCP | Allow | RDP to Bastion (optional, tighten) |
| 120 | AllowVNetInbound | 10.0.0.0/8 | Any | Any | Allow | Internal VNet communication |
| 4096 | DenyAllInbound | Any | Any | Any | Deny | Default deny |

#### Outbound Rules

| Priority | Name | Destination | Port | Protocol | Action | Purpose |
|----------|------|-------------|------|----------|--------|---------|
| 100 | AllowAllOutbound | Any (0.0.0.0/0) | Any | Any | Allow | All outbound traffic (includes internet) |
| 4096 | DenyAllOutbound | Any | Any | Any | Deny | Default deny (overridden by allow above) |

**Notes**:
- SSH/RDP to bastion restricted to internet in demo; restrict to corporate IP range in production
- Bastion itself provides secure tunneling, so bastion's outbound rules must allow SSH (22) to spoke subnets

### 5.2 UAT Spoke NSG

**NSG Name**: `nsg-spoke-uat-eus-001`
**Associated Subnets**: ApplicationSubnet, DataSubnet, ManagementSubnet

#### Inbound Rules

| Priority | Name | Source | Dest Port | Protocol | Action | Purpose |
|----------|------|--------|-----------|----------|--------|---------|
| 100 | AllowSSHFromBastion | 10.0.2.0/24 | 22 | TCP | Allow | SSH from Bastion only |
| 110 | AllowRDPFromBastion | 10.0.2.0/24 | 3389 | TCP | Allow | RDP from Bastion only |
| 120 | AllowHTTPFromFW | 10.0.0.0/24 | 80 | TCP | Allow | HTTP from internal firewall |
| 130 | AllowHTTPSFromFW | 10.0.0.0/24 | 443 | TCP | Allow | HTTPS from internal firewall |
| 140 | AllowAppInternalTalk | 10.1.0.0/24 | 3306 | TCP | Allow | MySQL between app/data subnets |
| 150 | AllowVNetInbound | 10.0.0.0/8 | Any | Any | Allow | Intra-VNet communication |
| 4096 | DenyAllInbound | Any | Any | Any | Deny | Default deny |

#### Outbound Rules

| Priority | Name | Destination | Port | Protocol | Action | Purpose |
|----------|------|-------------|------|----------|--------|---------|
| 100 | AllowAllOutbound | Any (0.0.0.0/0) | Any | Any | Allow | All outbound (via FW UDR) |
| 4096 | DenyAllOutbound | Any | Any | Any | Deny | Default deny (overridden) |

**Notes**:
- No direct Internet inbound to spoke VMs (security principle)
- All inbound via Bastion (SSH) or Firewall (app traffic)
- Outbound routed through firewall via UDR `0.0.0.0/0`

### 5.3 Prod Spoke NSG

**NSG Name**: `nsg-spoke-prod-eus-001`
**Associated Subnets**: ApplicationSubnet, DataSubnet, ManagementSubnet

#### Inbound Rules

| Priority | Name | Source | Dest Port | Protocol | Action | Purpose |
|----------|------|--------|-----------|----------|--------|---------|
| 100 | AllowSSHFromBastion | 10.0.2.0/24 | 22 | TCP | Allow | SSH from Bastion only (restricted) |
| 110 | AllowHTTPFromFW | 10.0.0.0/24 | 80 | TCP | Allow | HTTP from firewall |
| 120 | AllowHTTPSFromFW | 10.0.0.0/24 | 443 | TCP | Allow | HTTPS from firewall |
| 130 | AllowAppInternalTalk | 10.2.0.0/24 | 3306 | TCP | Allow | MySQL (data subnet only) |
| 140 | AllowVNetInbound | 10.2.0.0/24 | Any | Any | Allow | Intra-spoke VNet only (more restrictive) |
| 4096 | DenyAllInbound | Any | Any | Any | Deny | Default deny |

#### Outbound Rules

| Priority | Name | Destination | Port | Protocol | Action | Purpose |
|----------|------|-------------|------|----------|--------|---------|
| 100 | AllowAllOutbound | Any (0.0.0.0/0) | Any | Any | Allow | All outbound (via FW UDR) |
| 4096 | DenyAllOutbound | Any | Any | Any | Deny | Default deny (overridden) |

**Notes**:
- Stricter than UAT: no inter-vnet peering communication allowed (different subnets only)
- RDP omitted for prod (SSH only)
- Database access restricted to data subnet only

---

## 6. Virtual Network Peering

### 6.1 Hub ↔ UAT Peering

**Peering Name**: `peering-hub-to-uat`
**Hub Side**:
- Allow forwarded traffic: **Yes**
- Allow gateway transit: **Yes**
- Use remote gateways: **No** (hub side)
- Allow virtual network access: **Yes**

**UAT Side**:
- Allow forwarded traffic: **Yes**
- Allow gateway transit: **No**
- Use remote gateways: **Yes** (UAT side)
- Allow virtual network access: **Yes**

**Effect**:
- Hub can forward traffic from firewall to UAT VMs
- UAT VMs traffic destined for hub/internet routed via hub firewall
- No direct internet gateway on UAT (hub is transit point)

### 6.2 Hub ↔ Prod Peering

**Peering Name**: `peering-hub-to-prod`
**Hub Side**:
- Allow forwarded traffic: **Yes**
- Allow gateway transit: **Yes**
- Use remote gateways: **No**
- Allow virtual network access: **Yes**

**Prod Side**:
- Allow forwarded traffic: **Yes**
- Allow gateway transit: **No**
- Use remote gateways: **Yes**
- Allow virtual network access: **Yes**

**Effect**: Same as Hub ↔ UAT peering

### 6.3 UAT ↔ Prod Peering (Optional)

**Decision**: Can be disabled or enabled based on requirement
- **Disabled** (Default): UAT and Prod are isolated (cannot communicate directly)
- **Enabled** (Optional): UAT ↔ Prod direct communication allowed (traffic not forced through FW)

**If Enabled**:
```hcl
# Each side allows bidirectional traffic
allow_virtual_network_access = true
allow_forwarded_traffic      = true
allow_gateway_transit        = false
```

**Recommendation**: Keep disabled for environment isolation, enable only if cross-environment integration required (and document firewall rules)

---

## 7. Azure Firewall Configuration

### 7.1 Firewall Properties

**Firewall Name**: `fw-eus-001`
**Location**: Hub VNet, AzureFirewallSubnet (10.0.1.0/24)
**SKU**: Standard (or Premium for advanced features)
**Public IP**: Assigned (for outbound NAT)
**Threat Intelligence**: Enabled (block known malicious IPs)

### 7.2 Application Rules

| Priority | Name | Source | Protocol | Destination | Port | Action |
|----------|------|--------|----------|-------------|------|--------|
| 100 | AllowHTTPS | 10.0.0.0/8 | HTTPS | Any | 443 | Allow |
| 110 | AllowHTTP | 10.0.0.0/8 | HTTP | Any | 80 | Allow |
| 120 | AllowDNS | 10.0.0.0/8 | DNS | Any | 53 | Allow |
| 130 | AllowNTP | 10.0.0.0/8 | NTP | time.nist.gov | 123 | Allow |
| 4096 | DenyAll | Any | Any | Any | Any | Deny |

### 7.3 Network Rules

| Priority | Name | Source | Protocol | Dest Port | Destination | Action |
|----------|------|--------|----------|-----------|-------------|--------|
| 100 | AllowSSHMgmt | 10.0.0.0/8 | TCP | 22 | 10.0.0.0/8 | Allow |
| 110 | AllowRDPMgmt | 10.0.0.0/8 | TCP | 3389 | 10.0.0.0/8 | Allow |
| 120 | AllowCustomApp | 10.0.0.0/8 | TCP | 8080 | Any | Allow |
| 4096 | DenyAll | Any | Any | Any | Any | Deny |

### 7.4 Firewall Logging

**Diagnostic Settings**:
- **Logs exported to**: Log Analytics Workspace
- **Logs collected**:
  - Application rule logs (hit/miss)
  - Network rule logs (hit/miss)
  - NAT rule logs
  - Threat intelligence events
- **Retention**: 90 days (adjustable)

---

## 8. Network Traffic Flows

### 8.1 Inbound Traffic (Internet → Azure App)

```
Step 1: Packet arrives at FW Public IP (20.XX.XX.XX:443)
        │
        ▼
Step 2: Azure Firewall NAT translation
        Source: 20.XX.XX.XX → 10.0.1.5 (firewall internal)
        │
        ▼
Step 3: Firewall evaluates Application Rules
        - Match HTTPS rule (port 443)
        - Check destination
        │
        ▼
Step 4: If allowed, packet forwarded to spoke
        Via UDR routing: 10.1.1.0/24 → Peering → UAT Spoke
        │
        ▼
Step 5: Packet arrives at UAT Spoke subnet
        │
        ▼
Step 6: UAT NSG evaluates Inbound Rules
        - Check source (10.0.0.0/24 FW) ✓
        - Check port (443) ✓
        - Check protocol (TCP) ✓
        │
        ▼
Step 7: If allowed, packet delivered to target VM (10.1.1.x:443)
        │
        ▼
Step 8: Application responds (reverse path)
```

### 8.2 Outbound Traffic (Azure App → Internet)

```
Step 1: VM in UAT spoke initiates outbound connection (10.1.1.10 → 8.8.8.8:443)
        │
        ▼
Step 2: NSG evaluates Outbound Rule
        - Default allow all (0.0.0.0/0) ✓
        │
        ▼
Step 3: Route table lookup: Destination 8.8.8.8
        - UDR match: 0.0.0.0/0 → Azure Firewall
        │
        ▼
Step 4: Packet routed to Firewall (10.0.1.5)
        │
        ▼
Step 5: Firewall NAT (SNAT)
        Source: 10.1.1.10 → 20.XX.XX.XX (FW Public IP)
        Destination: 8.8.8.8:443 (unchanged)
        │
        ▼
Step 6: Firewall evaluates Network Rules
        - Check source (10.0.0.0/8 spoke) ✓
        - Check destination (any) ✓
        - Check port (443) ✓
        │
        ▼
Step 7: If allowed, packet egresses via FW Public IP → Internet
        │
        ▼
Step 8: Internet responds to FW Public IP
        │
        ▼
Step 9: Firewall de-SNAT: response to original VM (10.1.1.10)
        │
        ▼
Step 10: Response delivered to VM
```

### 8.3 Inter-Spoke Traffic (UAT ↔ Hub)

```
Step 1: VM in UAT spoke initiates connection to management tool in Hub
        Source: 10.1.1.10 → Destination: 10.0.4.5
        │
        ▼
Step 2: Route table lookup: Destination 10.0.4.0/24
        - Match: 10.0.0.0/16 (Hub) → Peering
        │
        ▼
Step 3: NSG outbound evaluation (UAT)
        - Rule: AllowVNetInbound 10.0.0.0/8 ✓
        │
        ▼
Step 4: Packet travels via VNet Peering (direct, no FW)
        │
        ▼
Step 5: NSG inbound evaluation (Hub)
        - Rule: AllowVNetInbound 10.0.0.0/8 ✓
        │
        ▼
Step 6: Packet delivered to Hub VM (10.0.4.5)
        │
        ▼
Step 7: Response follows reverse path (no FW traversal)
```

### 8.4 Management Access (Bastion → Spoke VM)

```
Step 1: Admin connects to Bastion public IP (SSH, 22)
        Admin IP (external) → Bastion Public IP:22
        │
        ▼
Step 2: Hub NSG evaluates inbound
        - Priority 100: AllowSSHFromInternet (0.0.0.0/0:22) ✓
        │
        ▼
Step 3: Bastion receives SSH, establishes session
        │
        ▼
Step 4: Admin issues: ssh to 10.1.1.10 (app vm in uat)
        │
        ▼
Step 5: Bastion initiates SSH to spoke VM
        Source: 10.0.2.x → Destination: 10.1.1.10:22
        │
        ▼
Step 6: Route table lookup from Bastion
        - UDR: 0.0.0.0/0 → FW (but 10.1.0.0/16 → Peering)
        - More specific match: 10.1.0.0/16 → Peering
        │
        ▼
Step 7: Bastion NSG outbound + Hub NSG outbound
        - AllowAllOutbound ✓
        │
        ▼
Step 8: Packet via VNet Peering → UAT Spoke
        │
        ▼
Step 9: UAT NSG evaluates inbound
        - Priority 100: AllowSSHFromBastion (10.0.2.0/24:22) ✓
        │
        ▼
Step 10: SSH session established to spoke VM
         Admin can now manage spoke VM securely through bastion
```

---

## 9. Network Segmentation & Micro-Segmentation

### 9.1 Macro-Segmentation (VNet/Subnet Level)

```
┌─────────────────────────────────────────────────────┐
│ MACRO SEGMENTATION: Environment Isolation           │
├─────────────────────────────────────────────────────┤
│                                                     │
│  UAT Environment          Prod Environment         │
│  ─────────────────        ───────────────          │
│  • 10.1.0.0/16            • 10.2.0.0/16            │
│  • Separate VNET          • Separate VNET          │
│  • Separate NSG           • Separate NSG           │
│  • Separate Route Tables  • Separate Route Tables  │
│  • Optional peering       • Optional peering       │
│    (disabled by default)  (disabled by default)    │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### 9.2 Micro-Segmentation (Subnet Level)

```
┌─────────────────────────────────────────────────────┐
│ MICRO SEGMENTATION: Tier Isolation                  │
├─────────────────────────────────────────────────────┤
│                                                     │
│  App Tier (10.1.1.0/24)                             │
│  ├─ SSH: Only from Bastion (10.0.2.0/24)          │
│  ├─ HTTP/HTTPS: Only from Firewall (10.0.0.0/24)  │
│  ├─ DB: Only to Data subnet (10.1.2.0/24)         │
│                                                     │
│  Data Tier (10.1.2.0/24)                            │
│  ├─ MySQL: Only from App tier (10.1.1.0/24)       │
│  ├─ SSH: Only from Bastion                         │
│  ├─ NO direct internet access (enforced by UDR)   │
│                                                     │
│  Management Tier (10.1.3.0/24)                      │
│  ├─ Monitoring agent: Any source                   │
│  ├─ Log collector: Any source                      │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### 9.3 Application Security Groups (ASG) [Future Enhancement]

For more granular control, Azure Application Security Groups can be used:

```hcl
# Example: Associate VMs to ASGs
azurerm_application_security_group "web_tier" {
  name = "asg-web-uat"
}

azurerm_application_security_group "db_tier" {
  name = "asg-db-uat"
}

# NSG rules reference ASGs (not subnets)
# Rule: "Allow MySQL from web tier to db tier"
# - Source: web_tier ASG
# - Port: 3306
# - Destination: db_tier ASG
```

---

## 10. DNS Resolution

### 10.1 DNS Strategy

**Azure-provided DNS**:
- Default: Azure DNS (168.63.169.254)
- VMs resolve `<vm-name>.internal.cloudapp.net`
- VMs resolve Azure services via private DNS zones

**Private DNS Zones** (Optional, Recommended):
```
Zone: iac-demo.internal
├─ hub-bastion.iac-demo.internal → 10.0.2.x
├─ uat-vm-01.iac-demo.internal → 10.1.1.x
└─ prod-vm-01.iac-demo.internal → 10.2.1.x
```

**Custom DNS** (If applicable):
- On-prem DNS: Integrate via DNS forwarders
- Conditional forwarding: Route specific domains to custom servers

---

## 11. Network Monitoring & Diagnostics

### 11.1 NSG Flow Logs

**Enabled on**:
- `nsg-hub-eus-001`
- `nsg-spoke-uat-eus-001`
- `nsg-spoke-prod-eus-001`

**Storage**:
- Storage Account: `stdiagnosticslogs`
- Container: `nsg-flow-logs`
- Retention: 90 days

**Log Content**:
- Source/Dest IP, port, protocol
- Allow/Deny decision
- Bytes, packets
- Flow hash (identifies connection)

### 11.2 Firewall Logging

**Logs**:
- Application rule hit/miss
- Network rule hit/miss
- NAT translations
- Threat intelligence events

**Destination**: Log Analytics Workspace
**Queries**:
```kusto
# Top blocked sources
AzureDiagnostics
| where ResourceType == "AZUREFIREWALLS"
| where action_s == "Deny"
| summarize count() by source_s
| top 10 by count_

# SNAT port exhaustion
AzureDiagnostics
| where ResourceType == "AZUREFIREWALLS"
| where action_s == "Deny"
| where msg_s contains "SNAT"
```

---

## 12. High Availability & Redundancy

### 12.1 Firewall Redundancy

**Current Model**: Single firewall instance
**HA Improvement**: Deploy firewall in Availability Zones

```
AZ1: Firewall instance 1 (10.0.1.5)
AZ2: Firewall instance 2 (10.0.1.6)
└─ Shared public IP (20.XX.XX.XX)
└─ Azure Load Balancer (internal) distributes traffic
```

### 12.2 Bastion Redundancy

**Current**: Single bastion instance
**HA Improvement**: Multiple instances (region/zone redundancy)
- Scale set or multiple instances in different AZs
- Public IP load balanced across instances

### 12.3 VNet Resilience

- VNets span availability zones automatically
- Peering is resilient (works across AZs)
- VNet flow-logs reduce false positives from transient network blips

---

## 13. Network Best Practices Implemented

✅ **Zero-Trust Network Access**
- Default deny all, explicitly allow required traffic
- No public IPs on workload VMs (bastion proxy)
- All inbound inspection (firewall + NSG)

✅ **Defense in Depth**
- Multiple filtering layers (firewall → NSG)
- Segmentation by environment and tier
- Centralized egress point (firewall NAT)

✅ **Audit & Compliance**
- All network changes logged (Activity Logs)
- Traffic flows logged (NSG Flow Logs)
- Threat intel integration (firewall)

✅ **Scalability**
- Address space allows 256 VNets (/16 each in 10.0.0.0/8)
- Subnets allow hundreds of VMs per tier
- Firewall throughput supports enterprise workloads

✅ **Cost Optimization**
- Firewall Standard SKU (not Premium unless needed)
- Bastion Standard (not Premium unless needed)
- VNet Peering costs only egress data transfer

---

## 14. Network Troubleshooting Guide

### Common Issues & Resolution

| Issue | Symptom | Troubleshooting |
|-------|---------|-----------------|
| VM cannot reach internet | 0% success to 8.8.8.8 | Check UDR, firewall rules, NSG outbound allow |
| Cannot SSH to Bastion | Connection refused | Check public IP, security group 22/TCP, NSG allow |
| Bastion → Spoke VM unreachable | SSH timeout | Check peering enabled, NSG allow SSH from bastion subnet |
| Cross-spoke communication fails | No response | Check if peering enabled, firewall allow rules, route table UDR |
| Firewall public IP not responding | Ping timeout | Check FW is deployed in AzureFirewallSubnet, diagnostics |

### Useful Commands

```bash
# Check effective routes on a VM NIC
az network nic show-effective-route-table --resource-group RG-UAT --name nic-vm01

# Check NSG rules applied to NIC
az network nic list-effective-network-security-groups --resource-group RG-UAT --name nic-vm01

# Test connectivity (from VM)
nmap -p 22 10.0.2.5  # Test SSH from spoke to bastion
curl -v http://10.0.1.5:8080  # Test firewall rule

# Query NSG Flow Logs
az network watcher flow-log show --resource-group RG-Hub --name flowlog-nsg-hub
```

---

## 15. Network Architecture Diagram (ASCII, Detailed)

```
╔════════════════════════════════════════════════════════════════════════════╗
║                    DETAILED NETWORK TOPOLOGY                               ║
╚════════════════════════════════════════════════════════════════════════════╝

                        ┌─────────────────────────┐
                        │   INTERNET              │
                        │   (0.0.0.0/0)           │
                        └────────────┬────────────┘
                                     │
                        ┌────────────▼────────────┐
                        │  PUBLIC IP (20.XX.XX.XX)│
                        │  (NAT for outbound)     │
                        └────────────┬────────────┘
                                     │
                        ┌────────────▼────────────┐
                        │ AZURE FIREWALL          │
                        │ fw-eus-001              │
                        │ IP: 10.0.1.5            │
                        │ Subnet: 10.0.1.0/24     │
                        │                         │
                        │ Rules:                  │
                        │ • App rules (HTTP/HTTPS)│
                        │ • Network rules (SSH)   │
                        │ • Threat intel enabled  │
                        └────────────┬────────────┘
                                     │
                 ┌───────────────────┼───────────────────┐
                 │                   │                   │
                 ▼                   ▼                   ▼
    ┌─────────────────────┐  ┌──────────────────┐  ┌──────────────────┐
    │   HUB VNET          │  │  UAT SPOKE VNET  │  │ PROD SPOKE VNET  │
    │   10.0.0.0/16       │  │  10.1.0.0/16     │  │  10.2.0.0/16     │
    │                     │  │                  │  │                  │
    │  ┌─────────────┐    │  │  ┌────────────┐  │  │  ┌────────────┐  │
    │  │ FW Subnet   │    │  │  │ App Subnet │  │  │  │ App Subnet │  │
    │  │ 10.0.1/24   │    │  │  │ 10.1.1/24  │  │  │  │ 10.2.1/24  │  │
    │  │             │    │  │  │            │  │  │  │            │  │
    │  │ • FW (10.x) │    │  │  │ • VM-uat01 │  │  │  │ • VM-p-01  │  │
    │  │   (Firewall)│    │  │  │   (10.x.x) │  │  │  │   (10.x.x) │  │
    │  │             │    │  │  │            │  │  │  │            │  │
    │  │ NSG: FW-NSG │    │  │  │ NSG: UAT   │  │  │  │ NSG: PROD  │  │
    │  │             │    │  │  │ Rules:     │  │  │  │ Rules:     │  │
    │  └─────────────┘    │  │  │ • SSH:22   │  │  │  │ • SSH:22   │  │
    │                     │  │  │   (bastion)│  │  │  │   (bastion)│  │
    │  ┌─────────────┐    │  │  │ • HTTP:80  │  │  │  │ • HTTP:80  │  │
    │  │ Bastion     │    │  │  │   (firewall)  │  │  │   (firewall)   │
    │  │ Subnet      │    │  │  │ • HTTPS:443│  │  │  │ • HTTPS:443│  │
    │  │ 10.0.2/24   │    │  │  │   (firewall)  │  │  │   (firewall)   │
    │  │             │    │  │  │            │  │  │  │            │  │
    │  │ • Bastion   │    │  │  └────────────┘  │  │  │ • LB (opt) │  │
    │  │   Host      │    │  │                  │  │  │            │  │
    │  │   10.0.2.x  │    │  │  ┌────────────┐  │  │  │ ┌────────────┐ │
    │  │ • Public IP │    │  │  │ Data Sub   │  │  │  │ │ Data Sub   │ │
    │  │   (bastion) │    │  │  │ 10.1.2/24  │  │  │  │ │ 10.2.2/24  │ │
    │  │             │    │  │  │            │  │  │  │ │            │ │
    │  │ NSG: HUB    │    │  │  │ • DB (opt) │  │  │  │ │ • DB (opt) │ │
    │  │ Rules:      │    │  │  │   10.x.x   │  │  │  │ │   10.x.x   │ │
    │  │ • SSH:22    │    │  │  │            │  │  │  │ │            │ │
    │  │   (internet)│    │  │  │ NSG: UAT   │  │  │  │ │ NSG: PROD  │ │
    │  │ • Allow VNet│    │  │  │ Rules:     │  │  │  │ │ Rules:     │ │
    │  │   inbound   │    │  │  │ • MySQL:33 │  │  │  │ │ • MySQL:33 │ │
    │  └─────────────┘    │  │  │   (apponly)│  │  │  │ │   (apponly)│ │
    │                     │  │  │            │  │  │  │ │            │ │
    │  ┌─────────────┐    │  │  └────────────┘  │  │  │ └────────────┘ │
    │  │ GW Subnet   │    │  │                  │  │  │                │
    │  │ 10.0.3/24   │    │  │  ┌────────────┐  │  │  │ ┌────────────┐ │
    │  │ (reserved)  │    │  │  │ Mgmt Sub   │  │  │  │ │ Mgmt Sub   │ │
    │  └─────────────┘    │  │  │ 10.1.3/24  │  │  │  │ │ 10.2.3/24  │ │
    │                     │  │  │            │  │  │  │ │            │ │
    │  ┌─────────────┐    │  │  │ • Monitor  │  │  │  │ │ • Monitor  │ │
    │  │ Mgmt Subnet │    │  │  │ • Backup   │  │  │  │ │ • Backup   │ │
    │  │ 10.0.4/24   │    │  │  │            │  │  │  │ │            │ │
    │  │ (jumpboxes) │    │  │  │ NSG: UAT   │  │  │  │ │ NSG: PROD  │ │
    │  └─────────────┘    │  │  │ (no restrictions)  │  │ (no restrictions)
    │                     │  │  │            │  │  │  │ │            │ │
    │  Route Table:       │  │  └────────────┘  │  │  │ └────────────┘ │
    │  • 10.0.0/16→Local  │  │                  │  │  │                │
    │  • 10.1.0/16→Peer   │  │  Route Table:    │  │  │ Route Table:   │
    │  • 10.2.0/16→Peer   │  │  • 10.1.0/16→   │  │  │ • 10.2.0/16→   │
    │  • 0.0.0/0→Internet │  │    Local        │  │  │   Local        │
    │                     │  │  • 10.0.0/16→   │  │  │ • 10.0.0/16→   │
    │                     │  │    Peering      │  │  │   Peering      │
    │                     │  │  • 0.0.0/0→     │  │  │ • 0.0.0/0→     │
    │                     │  │    Firewall(UDR)│  │  │   Firewall(UDR)│
    │                     │  │                  │  │  │                │
    └─────────────────────┘  └──────────────────┘  └──────────────────┘
            │                        │                       │
            │         VNet Peering   │         VNet Peering  │
            │──────────────────────────────────────────────
            │ (allow_forwarded_traffic = true)
            │ (use_remote_gateways = true on spoke)
```

---

**Document Version**: 1.0  
**Last Updated**: March 31, 2026  
**Network Architecture Owner**: Infrastructure Team
