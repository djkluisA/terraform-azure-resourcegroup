
provider "azurerm" {
  skip_provider_registration = true
  features {}
}

data "azurerm_resource_group" "example" {
  name = "example-resource-group"
}

data "azurerm_client_config" "current" {}

data "azurerm_virtual_network" "example" {
  name                = "example-vnet"
  resource_group_name = data.azurerm_resource_group.example.name
}

data "azurerm_subnet" "example" {
  name                 = "example-subnet"
  virtual_network_name = data.azurerm_virtual_network.example.name
  resource_group_name  = data.azurerm_resource_group.example.name
}

variable "address_space" {}
variable "address_prefixes" {}
variable "address_prefixes2" {}
variable "private_ip_address" {}

output "resource_group_id" {
  value = data.azurerm_resource_group.example.id
}

output "client_id" {
  value = data.azurerm_client_config.current.client_id
}
