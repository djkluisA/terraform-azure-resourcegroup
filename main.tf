
provider "azurerm" {
  skip_provider_registration = true
  features {}
}

data "azurerm_resource_group" "rg" {
  name = "1-3baf3667-playground-sandbox"
}

data "azurerm_client_config" "current" {}

resource "azurerm_virtual_network" "vnet" {
  name                = "my-vnet"
  resource_group_name = data.azurerm_resource_group.rg.name
  address_space       = []
}

resource "azurerm_subnet" "subnet" {
  name                 = "my-subnet"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = []
}

resource "azurerm_network_interface" "nic1" {
  name                      = "my-nic"
  location                  = data.azurerm_resource_group.rg.location
  resource_group_name       = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "my-nic-configuration"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "nic_sg" {
  network_interface_id      = azurerm_network_interface.nic1.id
  network_security_group_id = ""
}

resource "azurerm_network_security_group" "nsg" {
  name                = "my-nsg"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_security_rule" "inbound" {
  name                       = "rule1"
  priority                   = 100
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "22"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
  network_security_group_name= azurerm_network_security_group.nsg.name
}

resource "azurerm_public_ip" "publicip" {
  name                = "mypublicip"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

resource "azurerm_network_interface_ip_configuration" "test" {
  name                          = "internal"
  subnet_id                     = azurerm_subnet.subnet.id
  network_interface_id          = azurerm_network_interface.nic1.id
  private_ip_address_allocation = "Static"
  private_ip_address            = var.private_ip_address
}

variable "address_space" {}
variable "address_prefixes" {}
variable "private_ip_address" {}
