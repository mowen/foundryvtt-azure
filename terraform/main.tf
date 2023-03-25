terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.9.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "mowentfstate"
    storage_account_name = "mowentfstatestorage"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"
    use_microsoft_graph  = true
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "foundry" {
  name     = "${local.env_prefix}rg"
  location = local.region
}

resource "azurerm_storage_account" "foundry" {
  name                     = "${local.storage_prefix}storage"
  location                 = azurerm_resource_group.foundry.location
  resource_group_name      = azurerm_resource_group.foundry.name
  account_tier             = "Standard"
  account_replication_type = "ZRS"

  network_rules {
    default_action = "Deny"
    virtual_network_subnet_ids = [
      azurerm_subnet.storage_subnet.id,
      azurerm_subnet.app_subnet.id
    ]
    ip_rules = local.my_client_ips
  }

  depends_on = [
    azurerm_virtual_network.foundry
  ]
}

resource "azurerm_storage_share" "foundry" {
  name                 = "${local.storage_prefix}share"
  storage_account_name = azurerm_storage_account.foundry.name
  quota                = 5
}

# Key Vault

resource "azurerm_key_vault" "foundry" {
  name                       = "${local.env_prefix}keyvault"
  location                   = azurerm_resource_group.foundry.location
  resource_group_name        = azurerm_resource_group.foundry.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "premium"
  soft_delete_retention_days = 7

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Create",
      "Get",
    ]

    secret_permissions = [
      "Set",
      "Get",
      "List",
      "Delete",
      "Purge",
      "Recover"
    ]
  }
}

data "local_sensitive_file" "secrets" {
  filename = local.secrets_file
}

resource "azurerm_key_vault_secret" "foundry_username" {
  name         = "foundry-username"
  value        = jsondecode(data.local_sensitive_file.secrets.content).foundry_username
  key_vault_id = azurerm_key_vault.foundry.id
}

resource "azurerm_key_vault_secret" "foundry_password" {
  name         = "foundry-password"
  value        = jsondecode(data.local_sensitive_file.secrets.content).foundry_password
  key_vault_id = azurerm_key_vault.foundry.id
}

resource "azurerm_key_vault_secret" "foundry_license_key" {
  name         = "foundry-license-key"
  value        = jsondecode(data.local_sensitive_file.secrets.content).foundry_license_key
  key_vault_id = azurerm_key_vault.foundry.id
}

resource "azurerm_key_vault_secret" "foundry_admin_key" {
  name         = "foundry-admin-key"
  value        = jsondecode(data.local_sensitive_file.secrets.content).foundry_admin_key
  key_vault_id = azurerm_key_vault.foundry.id
}
