'''
provider "azurerm" {
  skip_provider_registration = true
  features {}
}

data "azurerm_resource_group" "example" {
  name = "1-3baf3667-playground-sandbox"
}

variable "address_space" {}

variable "address_prefixes" {}

resource "azurerm_virtual_network" "example" {
  name                = "vnet1"
  address_space       = var.address_space
  location            = data.azurerm_resource_group.example.location
  resource_group_name = data.azurerm_resource_group.example.name
}

resource "azurerm_subnet" "example" {
  name                 = "sbnet1"
  address_prefixes     = var.address_prefixes
  resource_group_name  = data.azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
}

resource "azurerm_network_interface" "example" {
  name                = "nic1"
  resource_group_name = data.azurerm_resource_group.example.name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.0.7"
  }
}

resource "azurerm_linux_virtual_machine" "example" {
  name                  = "vm1"
  resource_group_name   = data.azurerm_resource_group.example.name
  location              = data.azurerm_resource_group.example.location
  size                  = "Standard_B2s"
  network_interface_ids = [azurerm_network_interface.example.id]

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    name              = "vm1osdisk"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_username                = "azureuser"
  admin_password                = "Manolita3232"
  disable_password_authentication = false
}
'''