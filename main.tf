
provider "azurerm" {
  features {}
  skip_provider_registration = true
}

data "azurerm_resource_group" "sandbox" {
  name = "1-3baf3667-playground-sandbox"
}

variable "address_space" {
  default = []
}

variable "address_prefixes" {
  default = []
}

variable "private_ip_address" {
  default = ""
}

resource "azurerm_virtual_network" "vnet1" {
  name                = "vnet1"
  address_space       = var.address_space
  location            = data.azurerm_resource_group.sandbox.location
  resource_group_name = data.azurerm_resource_group.sandbox.name
}

resource "azurerm_subnet" "sbnet1" {
  name                 = "sbnet1"
  resource_group_name  = data.azurerm_resource_group.sandbox.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = var.address_prefixes
}

resource "azurerm_network_interface" "nic1" {
  name                = "nic1"
  location            = data.azurerm_resource_group.sandbox.location
  resource_group_name = data.azurerm_resource_group.sandbox.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.sbnet1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.private_ip_address
  }
}

resource "azurerm_linux_virtual_machine" "vm1" {
  name                  = "vm1"
  location              = data.azurerm_resource_group.sandbox.location
  resource_group_name   = data.azurerm_resource_group.sandbox.name
  size                  = "Standard_B2s"
 
  os_disk {
    name              = "${azurerm_linux_virtual_machine.vm1.name}-osdisk"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
    create_option     = "FromImage"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  admin_username = "azureuser"
  admin_password = "Manolita3232"

  connection {
    type        = "ssh"
    host        = azurerm_network_interface.nic1.private_ip_address
    user        = "azureuser"
    private_key = file("~/.ssh/id_rsa")
  }

  os_profile {
    computer_name  = azurerm_linux_virtual_machine.vm1.name
    admin_username = "azureuser"

    linux_configuration {
      disable_password_authentication = true
    }
  }

  network_interface_ids = [azurerm_network_interface.nic1.id]
}
