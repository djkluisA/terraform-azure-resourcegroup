
# provider configuration
provider "azurerm" {
  features {}
  skip_provider_registration = true
}

# define data for existing resource group
data "azurerm_resource_group" "existing" {
  name = "1-3baf3667-playground-sandbox"
}

# define data for client config
data "azurerm_virtual_network" "existing" {
  name                = "existing-virtual-network"
  resource_group_name = data.azurerm_resource_group.existing.name
}

# define virtual network
resource "azurerm_virtual_network" "example" {
  name                = "example-virtual-network"
  location            = data.azurerm_resource_group.existing.location
  resource_group_name = data.azurerm_resource_group.existing.name
  address_space       = []
  address_prefixes    = []
}

# define subnet
resource "azurerm_subnet" "example" {
  name                 = "example-subnet"
  resource_group_name  = data.azurerm_resource_group.existing.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = []
}

# define network interface
resource "azurerm_network_interface" "example" {
  name                = "example-nic"
  location            = data.azurerm_resource_group.existing.location
  resource_group_name = data.azurerm_resource_group.existing.name

  ip_configuration {
    name                          = "example-ipconfig"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Static"
    private_ip_address            = ""
  }
}
