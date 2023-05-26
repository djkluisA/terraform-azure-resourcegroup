
resource "azurerm_virtual_network" "vnet1" {
  name                = "vnet1"
  address_space       = var.address_space
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
}
