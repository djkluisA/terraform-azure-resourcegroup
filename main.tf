
provider "azurerm" {
  skip_provider_registration = true
  features {
    virtual_machine {
      delete_os_disk_on_deletion = true
    }
  }
}

data "azurerm_resource_group" "example" {
  name = "1-3baf3667-playground-sandbox"
}

variable "address_space" {}

variable "address_prefixes" {}

variable "private_ip_address" {}

resource "azurerm_virtual_network" "vnet1" {
  name                = "vnet1"
  location            = data.azurerm_resource_group.example.location
  resource_group_name = data.azurerm_resource_group.example.name
  address_space       = var.address_space
}

resource "azurerm_subnet" "sbnet1" {
  name                 = "sbnet1"
  resource_group_name  = data.azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = var.address_prefixes
}

resource "azurerm_network_interface" "nic1" {
  name                = "nic1"
  location            = data.azurerm_resource_group.example.location
  resource_group_name = data.azurerm_resource_group.example.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.sbnet1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.private_ip_address
  }
}

resource "azurerm_linux_virtual_machine" "vm1" {
  name                = "vm1"
  resource_group_name = data.azurerm_resource_group.example.name
  location            = data.azurerm_resource_group.example.location
  size                = "Standard_B2s"

  admin_username = "azureuser"

  admin_password = "Manolita3232"

  disable_password_authentication = false

  storage_os_disk {
    name              = "${azurerm_linux_virtual_machine.vm1.name}-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  network_interface_ids = [
    azurerm_network_interface.nic1.id
  ]
}
