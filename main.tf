
provider "azurerm" {
  features {}
  skip_provider_registration = true
}

data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "rg" {
  name = "1-52c8b3d4-playground-sandbox"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "myvnet"
  address_space       = var.address_space
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "mysubnet"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.address_prefixes
}

resource "azurerm_network_interface" "nic" {
  name                = "mynic"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "myipconfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.private_ip_address
  }
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_key_vault_secret" "public_key" {
  name         = "mypublickey"
  value        = tls_private_key.private_key.public_key_openssh
  key_vault_id = data.azurerm_key_vault.kv.id
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "myvm"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  size                = "Standard_B2s"
  admin_username      = "azureuser"
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  os_disk {
    name              = "myosdisk"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  admin_ssh_key {
    username   = "azureuser"
    public_key = azurerm_key_vault_secret.public_key.value
  }
}

resource "azurerm_bastion_host" "bastion" {
  name                = "mybastion"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  sku                 = "Standard"
  ip_configuration {
    name      = "myipconfig"
    public_ip_address_id = azurerm_public_ip.pip.id
  }
  subnet_id = azurerm_subnet.subnet.id
}

resource "azurerm_public_ip" "pip" {
  name                = "mypip"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

data "azurerm_key_vault" "kv" {
  name                = "mykeyvault"
  resource_group_name = data.azurerm_resource_group.rg.name
}

variable "address_space" {}
variable "address_prefixes" {}
variable "private_ip_address" {}
variable "address_prefixes2" {}
