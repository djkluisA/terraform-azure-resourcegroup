
provider "azurerm" {
  features {}
  skip_provider_registration = true
}

data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "example" {
  name = "resource-group1-a6e44407-playground-sandbox"
}

resource "azurerm_virtual_network" "example" {
  name                = "example-network"
  address_space       = var.address_space
  location            = data.azurerm_resource_group.example.location
  resource_group_name = data.azurerm_resource_group.example.name

  subnet {
    name           = "example-subnet"
    address_prefix = var.address_prefixes
  }

  subnet {
    name           = "example-subnet2"
    address_prefix = var.address_prefixes2
  }
}

resource "azurerm_network_interface" "example" {
  name                = "example-nic"
  location            = data.azurerm_resource_group.example.location
  resource_group_name = data.azurerm_resource_group.example.name

  ip_configuration {
    name                          = "example-ipconfig"
    subnet_id                     = element(azurerm_virtual_network.example.subnet.*.id, 0)
    private_ip_address_allocation = "Static"
    private_ip_address            = var.private_ip_address
  }
}

variable "address_space" {}

variable "address_prefixes" {}

variable "address_prefixes2" {}

variable "private_ip_address" {}

