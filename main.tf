
provider "azurerm" {
  skip_provider_registration = true
  features {}
}

data "azurerm_resource_group" "sandbox" {
  name = "1-3baf3667-playground-sandbox"
}

variable "address_space" {}

variable "address_prefixes" {}

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
  address_prefixes     = [var.address_prefixes]
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
  network_interface_ids = [azurerm_network_interface.nic1.id]

  storage_os_disk {
    name              = "${azurerm_linux_virtual_machine.vm1.name}-osdisk"
    storage_account_type = "Standard_LRS"
    caching           = "ReadWrite"
    create_option     = "FromImage"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = azurerm_linux_virtual_machine.vm1.name
    admin_username = "azureuser"
    admin_password = "Manolita3232"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}
