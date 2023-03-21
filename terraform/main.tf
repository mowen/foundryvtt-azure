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
}

resource "azurerm_storage_share" "foundry" {
  name                 = "${local.storage_prefix}share"
  storage_account_name = azurerm_storage_account.foundry.name
  quota                = 5
}
