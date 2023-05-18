
resource "azurerm_virtual_network" "vnet1" {
  name                = "vnet1"
  address_space       = var.address_space
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  
  subnet {
    name           = "sbnet1"
    address_prefix = "10.0.0.0/16"
  }
}

resource "azurerm_network_interface" "nic1" {
  name                = "nic1"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_virtual_network.vnet1.subnet.id
    private_ip_address            = "10.0.0.7"
    private_ip_address_allocation = "Static"
  }
}

resource "azurerm_linux_virtual_machine" "vm1" {
  name                  = "vm1"
  resource_group_name   = data.azurerm_resource_group.rg.name
  location              = data.azurerm_resource_group.rg.location
  size                  = "Standard_B2s"
  admin_username        = "azureuser"
  admin_password        = "Manolita3232"
  disable_password_authentication = false
 
  network_interface_ids = [azurerm_network_interface.nic1.id]

  os_disk {
    name              = "osdisk"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
}

data "azurerm_resource_group" "rg" {
  name = "1-a21e6146-playground-sandbox"
}

variable "address_space" {} 
