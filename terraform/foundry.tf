# Config for Caddy taken from https://itnext.io/automatic-https-with-azure-container-instances-aci-4c4c8b03e8c9 

resource "azurerm_storage_account" "caddy" {
  name                      = "${local.storage_prefix}caddystorage"
  resource_group_name       = azurerm_resource_group.foundry.name
  location                  = azurerm_resource_group.foundry.location
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  enable_https_traffic_only = true
}

resource "azurerm_storage_share" "caddy" {
  name                 = "${local.storage_prefix}caddyshare"
  storage_account_name = azurerm_storage_account.caddy.name
  quota                = 1
}

resource "azurerm_container_group" "foundry" {
  name                = "${local.env_prefix}containers"
  location            = azurerm_resource_group.foundry.location
  resource_group_name = azurerm_resource_group.foundry.name
  ip_address_type     = "Public"
  dns_name_label      = "foundry"
  os_type             = "Linux"

  depends_on = [
    azurerm_storage_account.foundry
  ]

  container {
    name   = "foundryvtt"
    image  = "felddy/foundryvtt:release"
    cpu    = "0.5"
    memory = "1.5"

    environment_variables = {
      "CONTAINER_PRESERVE_CONFIG" = "true"
      "FOUNDRY_PROXY_PORT"        = "443"
      "FOUNDRY_HOSTNAME"          = local.dns_name
    }

    secure_environment_variables = {
      "FOUNDRY_USERNAME"    = var.FOUNDRY_USERNAME
      "FOUNDRY_PASSWORD"    = var.FOUNDRY_PASSWORD
      "FOUNDRY_ADMIN_KEY"   = var.FOUNDRY_ADMIN_KEY
      "FOUNDRY_LICENSE_KEY" = var.FOUNDRY_LICENSE_KEY
    }

    volume {
      name                 = "foundry-data-mount"
      storage_account_name = azurerm_storage_account.foundry.name
      storage_account_key  = azurerm_storage_account.foundry.primary_access_key
      share_name           = azurerm_storage_share.foundry.name
      mount_path           = "/data"
    }
  }

  container {
    name   = "caddy"
    image  = "caddy"
    cpu    = "0.5"
    memory = "0.5"

    ports {
      port     = 443
      protocol = "TCP"
    }

    ports {
      port     = 80
      protocol = "TCP"
    }

    volume {
      name                 = "foundry-caddy-data"
      mount_path           = "/data"
      storage_account_name = azurerm_storage_account.caddy.name
      storage_account_key  = azurerm_storage_account.caddy.primary_access_key
      share_name           = azurerm_storage_share.caddy.name
    }

    commands = ["caddy", "reverse-proxy", "--from", local.dns_name, "--to", "localhost:30000"]
  }
}

data "azurerm_container_group" "foundry" {
  name                = azurerm_container_group.foundry.name
  resource_group_name = azurerm_resource_group.foundry.name
}
