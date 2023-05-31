
provider "azurerm" {
  skip_provider_registration = true
}

data "azurerm_resource_group" "rg" {
  name = "resource group1-a6e44407-playground-sandbox"
}

data "azurerm_client_config" "current" {}

resource "azurerm_virtual_network" "vnet" {
  name                = "myvnet"
  address_space       = var.address_space
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  features {
    disable_advanced_networking = true
  }

  subnets {
    name           = "subnet1"
    address_prefix = var.address_prefixes
  }

  subnets {
    name           = "subnet2"
    address_prefix = var.address_prefixes2
  }
}

resource "azurerm_subnet_network_security_group_association" "example" {
  subnet_id                 = azurerm_virtual_network.vnet.subnets[0].id
  network_security_group_id = azurerm_network_security_group.example.id
}

resource "azurerm_network_security_group" "example" {
  name                = "example-nsg"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_network_interface" "example" {
  name                = "example-nic"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_virtual_network.vnet.subnets[0].id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.private_ip_address
  }
}

