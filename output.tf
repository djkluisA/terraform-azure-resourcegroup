output "object" {
  description = "Returns the full set of resource group object created"
  depends_on = [azurerm_resource_group.example]

  value = azurerm_resource_group.example
}

output "names" {
  description = "Returns a map of resource_group key of resource_group name"
  depends_on = [azurerm_resource_group.example]

    value = {
    for i in keys(azurerm_resource_group.example):
     i => azurerm_resource_group.example[i].name
  }
}

output "ids" {
  description = "Returns a map of resource_group key -> resource_group id"
  depends_on = [azurerm_resource_group.example]

    value = {
    for i in keys(azurerm_resource_group.example):
     i => azurerm_resource_group.example[i].id
  }
}