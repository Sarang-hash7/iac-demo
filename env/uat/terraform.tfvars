# ========================
# Overrides (only when needed)
# ========================

vm_config = {
  app = {
    vm_size         = "Standard_B2s"
    os_disk_size_gb = 30
    os_disk_type    = "StandardSSD_LRS"
    subnet          = "app"
    public_ip       = true
    admin_username  = "azureuser"
  }

  db = {
    vm_size         = "Standard_B2s"
    os_disk_size_gb = 30
    os_disk_type    = "StandardSSD_LRS"
    subnet          = "db"
    public_ip       = false
    admin_username  = "azureuser"
  }
}

nsg_rules = [
  {
    name                   = "allow-http"
    priority               = 100
    direction              = "Inbound"
    access                 = "Allow"
    protocol               = "Tcp"
    source_prefixes        = ["*"]
    destination_port_range = ["80"] # ← list with a single string
  },
  {
    name                   = "allow-https"
    priority               = 110
    direction              = "Inbound"
    access                 = "Allow"
    protocol               = "Tcp"
    source_prefixes        = ["*"]
    destination_port_range = ["443"] # ← list with a single string
  }
]

common_tags = {
  project     = "webapp"
  environment = "uat"
  owner       = "sarang.gupta@cloud4c.com"
}

kv_name = "kv-uat-02"

ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCzxwAxKsNbQUczv0xzaiZvXg69kkS31UoZqFJMAW+HJyOqzCEueeZxvkrGEjUFYYU0IvuLo+ASanfAgdk4JhQ15PXyvGWq3lpPjGcfMh2J6cEk4TKn67nirms7NIX6NZ/jLzXzLFqjRqWqD/kud6iPMZzJsmuxZbDT9jrasw+I++l9MAEjiiP2Z9k6IR0gQGooIYvoxxDBNUh3THfcTvLIK4DARxxDPT93Y4e41xTtivaGsMBklAViziLB5jfmevXgmjuht8WCBhrKZQhNsdlGPiSMPUEfrUJKiTtFIi8pLqNkyCbCKFuvmPWxUDNVn8gGL2kyc2FvkQyBCVtAAZjw6M/rnDe1vf3MLz6/RYPDzVORYgTDY2k2bncukoKLljNnbWmgYa4b19kGcCFd8nNin5bq2DF7MaxaJYJv3gqOr2Fx/XwUeNVW2YpX6PZM65D/ZvuxJSOeukz72YSOSdylyZFpyG0ZIcN5+jyTSuKjEUFQH5MSUpsFgzWdYwMnaoAdpyUSAhfzPb6teNI2ZtrO3+t1cw9SJ/09IPZUr3mgShbsg9iPnM9mIHPigFHRB2WcfwAJ036/unCFRpiyYfc0ufpEhJmpvDMM4GlhcK+Er1dMnAjcHp1fNjDsEjiqC1LDT3pHHQZkwjf7YeNdjHmOnow8tDgKSP6Sz6Z7nclylQ=="