terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      
    }
    tls = {
      source = "hashicorp/tls"
      
    }
    
  }  
}
provider "azurerm" {
  features {}
  skip_provider_registration = true
}

data "azurerm_resource_group" "test" {
  name = "1-cf24e0ec-playground-sandbox"
}

resource "azurerm_virtual_network" "vnet1" {
  name                = "vnet1"
  address_space       = ["10.0.0.0/8"]
  location            = data.azurerm_resource_group.test.location
  resource_group_name = data.azurerm_resource_group.test.name
}

resource "azurerm_subnet" "sb1" {
  name                 = "sb1"
  address_prefixes     = ["10.0.0.0/16"]
  virtual_network_name = azurerm_virtual_network.vnet1.name
  resource_group_name  = data.azurerm_resource_group.test.name
}
