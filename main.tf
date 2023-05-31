
provider "azurerm" {
  features {}
  skip_provider_registration = true
}

data "azurerm_resource_group" "rg" {
  name = "resource_group1-a6e44407-playground-sandbox"
}

data "azurerm_client_config" "current" {}

resource "azurerm_network_interface" "nic1" {
  name                = "nic1"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.private_ip_address
  }
}

resource "azurerm_subnet" "subnet1" {
  name                 = "subnet1"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = "vnet1"
  address_prefixes     = var.address_prefixes
}

resource "azurerm_virtual_network" "vnet1" {
  name                = "vnet1"
  address_space       = var.address_space
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_network_interface_backend_address_pool_association" "nic1_bap1" {
  network_interface_id    = azurerm_network_interface.nic1.id
  ip_configuration_name   = azurerm_network_interface.nic1.ip_configuration[0].name
  backend_address_pool_id = azurerm_lb_backend_address_pool.bap1.id
}

resource "azurerm_lb_backend_address_pool" "bap1" {
  name                = "bap1"
  resource_group_name = data.azurerm_resource_group.rg.name
  loadbalancer_id     = azurerm_lb.lb1.id
}

resource "azurerm_lb" "lb1" {
  name                = "lb1"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  sku                 = "Basic"

  frontend_ip_configuration {
    name                          = "PublicIPAddress"
    public_ip_address_id          = azurerm_public_ip.publicip1.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_public_ip" "publicip1" {
  name                = "publicip1"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

variable "address_space" {}
variable "address_prefixes" {}
variable "private_ip_address" {}
