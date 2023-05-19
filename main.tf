
provider "azurerm" {
  features {}
  skip_provider_registration = true
}

data "azurerm_resource_group" "example" {
  name = "1-3baf3667-playground-sandbox"
}

variable "address_space" {
  default = ["10.0.0.0/16"]
}

variable "address_prefixes" {
  default = ["10.0.1.0/24"]
}

variable "private_ip_address" {
  default = "10.0.1.4"
}

resource "azurerm_virtual_network" "example" {
  name                = "vnet1"
  location            = data.azurerm_resource_group.example.location
  resource_group_name = data.azurerm_resource_group.example.name
  address_space       = var.address_space
}

resource "azurerm_subnet" "example" {
  name                 = "sbnet1"
  resource_group_name  = data.azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = var.address_prefixes
}

resource "azurerm_network_interface" "example" {
  name                = "nic1"
  location            = data.azurerm_resource_group.example.location
  resource_group_name = data.azurerm_resource_group.example.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address            = var.private_ip_address
    private_ip_address_allocation = "Static"
  }
}

resource "azurerm_linux_virtual_machine" "example" {
  name                = "vm1"
  resource_group_name = data.azurerm_resource_group.example.name
  location            = data.azurerm_resource_group.example.location
  size                = "Standard_B2s"

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    name                 = "osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_username                 = "azureuser"
  admin_password                 = "Manolita3232"
  disable_password_authentication = false

  network_interface_ids = [azurerm_network_interface.example.id]
}
