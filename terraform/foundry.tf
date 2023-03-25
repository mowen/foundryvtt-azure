resource "azurerm_service_plan" "foundry" {
  name                = "${local.env_prefix}appserviceplan"
  resource_group_name = azurerm_resource_group.foundry.name
  location            = azurerm_resource_group.foundry.location
  os_type             = "Linux"
  sku_name            = "B1"
}

resource "azurerm_linux_web_app" "foundry" {
  name                = "${local.env_prefix}webapp"
  resource_group_name = azurerm_resource_group.foundry.name
  location            = azurerm_service_plan.foundry.location
  service_plan_id     = azurerm_service_plan.foundry.id

  depends_on = [
    azurerm_virtual_network.foundry
  ]

  app_settings = {
    "FOUNDRY_PROXY_PORT"         = "443"
    "FOUNDRY_HOSTNAME"           = local.dns_name
    "CONTAINER_PRESERVE_CONFIG"  = "true"
    "DOCKER_REGISTRY_SERVER_URL" = "https://index.docker.io/v1"
    "WEBSITES_PORT"              = "30000"

    "FOUNDRY_USERNAME"    = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.foundry_username.id})"
    "FOUNDRY_PASSWORD"    = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.foundry_password.id})"
    "FOUNDRY_ADMIN_KEY"   = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.foundry_admin_key.id})"
    "FOUNDRY_LICENSE_KEY" = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.foundry_license_key.id})"
  }

  identity {
    type = "SystemAssigned"
  }

  storage_account {
    name         = "foundry-data-mount"
    type         = "AzureFiles"
    account_name = azurerm_storage_account.foundry.name
    share_name   = azurerm_storage_share.foundry.name
    mount_path   = "/data"
    access_key   = azurerm_storage_account.foundry.primary_access_key
  }

  site_config {
    application_stack {
      docker_image     = "felddy/foundryvtt"
      docker_image_tag = "release"
    }
  }
}

resource "azurerm_app_service_virtual_network_swift_connection" "foundry_app_subnet" {
  app_service_id = azurerm_linux_web_app.foundry.id
  subnet_id      = azurerm_subnet.app_subnet.id
}

data "azurerm_linux_web_app" "foundry" {
  name                = azurerm_linux_web_app.foundry.name
  resource_group_name = azurerm_resource_group.foundry.name
}

resource "azurerm_key_vault_access_policy" "appservice" {
  key_vault_id = azurerm_key_vault.foundry.id
  tenant_id    = data.azurerm_linux_web_app.foundry.identity[0].tenant_id
  object_id    = data.azurerm_linux_web_app.foundry.identity[0].principal_id

  secret_permissions = [
    "Get",
    "List"
  ]
}

resource "azurerm_app_service_custom_hostname_binding" "foundry" {
  hostname            = local.dns_name
  app_service_name    = azurerm_linux_web_app.foundry.name
  resource_group_name = azurerm_resource_group.foundry.name
}

resource "azurerm_app_service_managed_certificate" "foundry" {
  custom_hostname_binding_id = azurerm_app_service_custom_hostname_binding.foundry.id
}

resource "azurerm_app_service_certificate_binding" "foundry" {
  hostname_binding_id = azurerm_app_service_custom_hostname_binding.foundry.id
  certificate_id      = azurerm_app_service_managed_certificate.foundry.id
  ssl_state           = "SniEnabled"
}

output "custom_domain_verification_id" {
  value     = azurerm_linux_web_app.foundry.custom_domain_verification_id
  sensitive = true
}
