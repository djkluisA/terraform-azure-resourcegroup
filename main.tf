
provider "azurerm" {
  skip_provider_registration = true
  features {}
}

data "azurerm_resource_group" "example" {
  name = "example-resource-group"
}

data "azurerm_client_config" "current" {}

output "resource_group_id" {
  value = data.azurerm_resource_group.example.id
}

output "client_id" {
  value = data.azurerm_client_config.current.client_id
}
