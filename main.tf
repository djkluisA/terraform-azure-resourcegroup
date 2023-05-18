
provider "azurerm" {
  features {}
  skip_provider_registration = true
}

data "azurerm_resource_group" "example" {
  name = "1-a21e6146-playground-sandbox"
}

resource "azurerm_virtual_network" "example" {
  name                = "vnet1"
  resource_group_name = data.azurerm_resource_group.example.name
  location            = data.azurerm_resource_group.example.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "example" {
  name                 = "sbnet1"
  resource_group_name  = data.azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.0.0/16"]
}

resource "azurerm_network_interface" "example" {
  name                = "nic1"
  location            = data.azurerm_resource_group.example.location
  resource_group_name = data.azurerm_resource_group.example.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address            = "10.0.0.7"
    private_ip_address_allocation = "Static"
  }
}

resource "azurerm_virtual_machine" "example" {
  name                  = "vm1"
  location              = data.azurerm_resource_group.example.location
  resource_group_name   = data.azurerm_resource_group.example.name
  network_interface_ids = [azurerm_network_interface.example.id]

  vm_size                        = "Standard_B2s"
  delete_os_disk_on_termination = true

  storage_os_disk {
    name              = "osdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "hostname"
    admin_username = "azureuser"
    admin_password = "Manolita3232"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}
