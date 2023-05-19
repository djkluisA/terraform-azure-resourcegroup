
resource "azurerm_virtual_network" "virtual_network" {
  name                = "vnet1"
  address_space       = var.address_space
  location            = data.azurerm_resource_group.resource_group.location
  resource_group_name = data.azurerm_resource_group.resource_group.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "sbnet1"
  resource_group_name  = data.azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.virtual_network.name
  address_prefixes     = var.address_prefixes
}

resource "azurerm_network_interface" "nic" {
  name                = "nic1"
  location            = data.azurerm_resource_group.resource_group.location
  resource_group_name = data.azurerm_resource_group.resource_group.name

  ip_configurations {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address            = var.private_ip_address
    private_ip_address_allocation = "Static"
  }
}

resource "azurerm_latest_virtual_machine_image" "vm_image" {
  publisher = "canonical"
  offer     = "UbuntuServer"
  sku       = "18.04-LTS"

  version = "latest"
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "vm1"
  resource_group_name = data.azurerm_resource_group.resource_group.name
  location            = data.azurerm_resource_group.resource_group.location
  size                = "Standard_B2s"

  admin_username              = "azureuser"
  admin_password              = "Manolita3232"
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  source_image_reference {
    publisher = azurerm_latest_virtual_machine_image.vm_image.publisher
    offer     = azurerm_latest_virtual_machine_image.vm_image.offer
    sku       = azurerm_latest_virtual_machine_image.vm_image.sku
    version   = azurerm_latest_virtual_machine_image.vm_image.version
  }

  os_disk {
    name              = "osdisk"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}

data "azurerm_resource_group" "resource_group" {
  name = "1-3baf3667-playground-sandbox"
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
}

variable "address_space" {}
variable "address_prefixes" {}
variable "private_ip_address" {}
