# ========================
# Overrides (only when needed)
# ========================

vm_config = {
  app = {
    vm_size         = "Standard_B2als_v2"
    os_disk_size_gb = 30
    os_disk_type    = "StandardSSD_LRS"
    subnet          = "app"
    public_ip       = true
    admin_username  = "azureuser"
  }

  db = {
    vm_size         = "Standard_B2als_v2"
    os_disk_size_gb = 30
    os_disk_type    = "StandardSSD_LRS"
    subnet          = "db"
    public_ip       = false
    admin_username  = "azureuser"
  }
}

app_nsg_rules = [
  {
    name                    = "allow-https"
    priority                = 100
    direction               = "Inbound"
    access                  = "Allow"
    protocol                = "Tcp"
    source_prefixes         = ["Internet"]
    destination_port_ranges = ["443"]
  },
  {
    name                    = "allow-ssh"
    priority                = 110
    direction               = "Inbound"
    access                  = "Allow"
    protocol                = "Tcp"
    source_prefixes         = ["103.241.182.128/32"]
    destination_port_ranges = ["22"]
  }
]

db_nsg_rules = [
  {
    name                    = "allow-postgres-from-app"
    priority                = 100
    direction               = "Inbound"
    access                  = "Allow"
    protocol                = "Tcp"
    source_prefixes         = ["10.10.1.0/24"]
    destination_port_ranges = ["5432"]
  },
  {
    name                    = "allow-ssh-from-admin"
    priority                = 110
    direction               = "Inbound"
    access                  = "Allow"
    protocol                = "Tcp"
    source_prefixes         = ["103.241.182.128/32"]
    destination_port_ranges = ["22"]
  }
]

common_tags = {
  project     = "webapp"
  environment = "uat"
  owner       = "sarang.gupta@cloud4c.com"
}

kv_name = "kv-uat-56712"

snapshot_start_date = "2026-05-13"
cleanup_start_date  = "2026-05-13"