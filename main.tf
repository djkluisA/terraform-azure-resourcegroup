
provider "azurerm" {
  skip_provider_registration = true
  features {}
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
 
  storage_os_disk {
    name              = "${azurerm_linux_virtual_machine.vm1.name}-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_data_disk {
    name            = "datadisk"
    disk_size_gb    = 64
    create_option   = "Empty"
    managed_disk_type = "Standard_LRS"
    lun             = 0
  }

  os_disk {
    name              = "${azurerm_linux_virtual_machine.vm1.name}-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  source_image_reference {
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
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  network_interface_ids = [
    azurerm_network_interface.nic1.id,
  ]
}
