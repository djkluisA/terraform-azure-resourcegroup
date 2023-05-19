
provider "azurerm" {
  skip_provider_registration = true
  features {}
}

data "azurerm_resource_group" "example" {
  name = "1-3baf3667-playground-sandbox"
}

data "azurerm_client_config" "example" {}

resource "azurerm_virtual_network" "example" {
  name                = "myvnet"
  address_space       = var.address_space
  location            = data.azurerm_resource_group.example.location
  resource_group_name = data.azurerm_resource_group.example.name

  subnet {
    name           = "mysubnet"
    address_prefix = var.address_prefixes
  }
}

resource "azurerm_network_interface" "example" {
  name                = "my-nic"
  location            = data.azurerm_resource_group.example.location
  resource_group_name = data.azurerm_resource_group.example.name

  ip_configuration {
    name                          = "myconfig"
    subnet_id                     = azurerm_virtual_network.example.subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.private_ip_address
  }
}

variable "address_space" {}

variable "address_prefixes" {}

variable "private_ip_address" {}
