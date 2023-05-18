
provider "azurerm" {
  skip_provider_registration = true
  features {}
}

data "azurerm_resource_group" "playground" {
  name = "1-a21e6146-playground-sandbox"
}

resource "azurerm_virtual_network" "vnet1" {
  name                = "vnet1"
  address_space       = ["10.0.0.0/8"]
  location            = data.azurerm_resource_group.playground.location
  resource_group_name = data.azurerm_resource_group.playground.name
}

resource "azurerm_subnet" "sbnet1" {
  name           = "sbnet1"
  resource_group_name = data.azurerm_resource_group.playground.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes = ["10.0.0.0/16"]
}

resource "azurerm_network_interface" "nic1" {
  name                = "nic1"
  location            = data.azurerm_resource_group.playground.location
  resource_group_name = data.azurerm_resource_group.playground.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.sbnet1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.0.7"
  }
}

resource "azurerm_linux_virtual_machine" "vm1" {
  name                = "vm1"
  location            = data.azurerm_resource_group.playground.location
  resource_group_name = data.azurerm_resource_group.playground.name
  size                = "Standard_B2s"

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

  admin_username = "azureuser"
  admin_password = "Manolita3232"
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.nic1.id
  ]
}
