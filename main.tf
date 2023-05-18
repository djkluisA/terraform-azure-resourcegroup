
resource "azurerm_virtual_network" "vnet1" {
  name                = "vnet1"
  address_space       = var.address_space

  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  tags = {
    environment = "sandbox"
  }
}

resource "azurerm_subnet" "sbnet1" {
  name                 = "sbnet1"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.0.0.0/16"]
}

resource "azurerm_network_interface" "nic1" {
  name                      = "nic1"
  location                  = data.azurerm_resource_group.rg.location
  resource_group_name       = data.azurerm_resource_group.rg.name
  internal_dns_name_label   = "nic1"
  enable_ip_forwarding      = false

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.sbnet1.id
    private_ip_address            = "10.0.0.7"
    private_ip_address_allocation = "Static"
  }
}

resource "azurerm_linux_virtual_machine" "vm1" {
  name                  = "vm1"
  location              = data.azurerm_resource_group.rg.location
  resource_group_name   = data.azurerm_resource_group.rg.name
  size                  = "Standard_B2s"

  network_interface_ids = [azurerm_network_interface.nic1.id]

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    name              = "${azurerm_linux_virtual_machine.vm1.name}-osdisk"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_username                = "azureuser"
  admin_password                = "Manolita3232"
  disable_password_authentication = false

  tags = {
    environment = "sandbox"
  }
}

data "azurerm_resource_group" "rg" {
  name = "1-a21e6146-playground-sandbox"
}

provider "azurerm" {
  version = "~> 2.0"

  skip_provider_registration = true

  features {}
}
