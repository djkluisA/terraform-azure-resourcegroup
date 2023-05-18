
provider "azurerm" {
  skip_provider_registration = true
  features {}
}

data "azurerm_resource_group" "resource_group" {
  name = "1-a21e6146-playground-sandbox"
}

variable "address_space" {}

resource "azurerm_virtual_network" "vnet1" {
  name                = "vnet1"
  address_space       = var.address_space
  location            = data.azurerm_resource_group.resource_group.location
  resource_group_name = data.azurerm_resource_group.resource_group.name
}

resource "azurerm_subnet" "sbnet1" {
  name                 = "sbnet1"
  resource_group_name  = data.azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.0.0.0/16"]
}


resource "azurerm_network_interface" "nic1" {
  name                = "nic1"
  location            = data.azurerm_resource_group.resource_group.location
  resource_group_name = data.azurerm_resource_group.resource_group.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.sbnet1.id
    private_ip_address            = "10.0.0.7"
    private_ip_address_allocation = "Static"
  }
}

resource "azurerm_virtual_machine" "vm1" {
  name                = "vm1"
  location            = data.azurerm_resource_group.resource_group.location
  resource_group_name = data.azurerm_resource_group.resource_group.name
  network_interface_ids = [
    azurerm_network_interface.nic1.id,
  ]

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "osdisk"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "vm1"
    admin_username = "azureuser"
    admin_password = "Manolita3232"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  hardware_profile {
    vm_size = "Standard_B2s"
  }
}

provider "azurerm" {
  skip_provider_registration = true
  features {}
}

 {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.0.0"
    }
  }
}
