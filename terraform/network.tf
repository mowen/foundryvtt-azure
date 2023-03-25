resource "azurerm_virtual_network" "foundry" {
  name                = "${local.env_prefix}vnet"
  location            = azurerm_resource_group.foundry.location
  resource_group_name = azurerm_resource_group.foundry.name

  address_space = ["10.0.0.0/16"]
}

# Storage Network
resource "azurerm_network_security_group" "storage" {
  name                = "${local.env_prefix}storage-nsg"
  location            = azurerm_resource_group.foundry.location
  resource_group_name = azurerm_resource_group.foundry.name
}

resource "azurerm_network_security_rule" "allow_port_80" {
  name                        = "Allow80Inbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.foundry.name
  network_security_group_name = azurerm_network_security_group.storage.name
}

resource "azurerm_network_security_rule" "allow_port_445" {
  name                        = "Allow445Inbound"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "445"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.foundry.name
  network_security_group_name = azurerm_network_security_group.storage.name
}

resource "azurerm_subnet" "storage_subnet" {
  name                 = "${local.env_prefix}storage-subnet"
  resource_group_name  = azurerm_resource_group.foundry.name
  virtual_network_name = azurerm_virtual_network.foundry.name

  address_prefixes = ["10.0.1.0/24"]

  service_endpoints = ["Microsoft.Storage"]
}

resource "azurerm_subnet_network_security_group_association" "foundry_storage_subnet" {
  subnet_id                 = azurerm_subnet.storage_subnet.id
  network_security_group_id = azurerm_network_security_group.storage.id
}

# App Network
resource "azurerm_network_security_group" "app" {
  name                = "${local.env_prefix}app-nsg"
  location            = azurerm_resource_group.foundry.location
  resource_group_name = azurerm_resource_group.foundry.name
}

resource "azurerm_network_security_rule" "allow_port_443" {
  name                        = "Allow443Inbound"
  priority                    = 102
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.foundry.name
  network_security_group_name = azurerm_network_security_group.app.name
}

resource "azurerm_subnet" "app_subnet" {
  name                 = "${local.env_prefix}app-subnet"
  resource_group_name  = azurerm_resource_group.foundry.name
  virtual_network_name = azurerm_virtual_network.foundry.name

  address_prefixes = ["10.0.2.0/24"]

  service_endpoints = ["Microsoft.Storage"]

  delegation {
    name = "delegation"

    service_delegation {
      name = "Microsoft.Web/serverFarms"
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "foundry_app_subnet" {
  subnet_id                 = azurerm_subnet.app_subnet.id
  network_security_group_id = azurerm_network_security_group.app.id
}