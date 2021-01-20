resource "azurerm_resource_group" "example" {
 for_each = var.resource_group
  name     = "example-rg-ld"
  location = "West Europe"
}
