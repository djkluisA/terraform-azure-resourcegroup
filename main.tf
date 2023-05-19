"""

provider "azurerm" {
  skip_provider_registration = true
  features {}
}

data "azurerm_resource_group" "existing" {
  name = "1-3baf3667-playground-sandbox"
}

variable "address_space" {}

variable "address_prefixes" {}

variable "private_ip_address" {} # Se agrega la variable faltante

resource "azurerm_virtual_network" "vnet1" {
  name                = "vnet1"
  location            = data.azurerm_resource_group.existing.location
  resource_group_name = data.azurerm_resource_group.existing.name
  address_space       = var.address_space
}

resource "azurerm_subnet" "sbnet1" {
  name                 = "sbnet1"
  resource_group_name  = data.azurerm_resource_group.existing.name
  virtual_network_name = azurerm_virtual_network.vnet1.name 
  address_prefixes     = var.address_prefixes
}

resource "azurerm_network_interface" "nic1" {
  name                      = "nic1"
  location                  = data.azurerm_resource_group.existing.location
  resource_group_name       = data.azurerm_resource_group.existing.name
  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.sbnet1.id
    private_ip_address            = var.private_ip_address
    private_ip_address_allocation = "static"
  }
}

resource "azurerm_linux_virtual_machine" "vm1" {
  name                  = "vm1"
  location              = data.azurerm_resource_group.existing.location
  resource_group_name   = data.azurerm_resource_group.existing.name
  size                  = "Standard_B2s"
  admin_username        = "azureuser"
  admin_password        = "Manolita3232"
  disable_password_authentication = false
  network_interface_ids = [azurerm_network_interface.nic1.id]

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  os_disk {
    name              = "osdisk1"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}

"""