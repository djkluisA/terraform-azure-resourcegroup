
provider "azurerm" {
  features {}
  skip_provider_registration = true
}

data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "rg" {
  name = "1-2f8e9908-playground-sandbox"
}

resource "azurerm_virtual_network" "vnet1" {
  name                = "vnet1"
  address_space       = var.address_space
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "sbnet1" {
  name                 = "sbnet1"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = var.address_prefixes
}

resource "azurerm_network_interface" "nic1" {
  name                = "nic1"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.sbnet1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.private_ip_address
  }
}

resource "tls_private_key" "example" {
  algorithm   = "RSA"
  rsa_bits    = 4096
}

resource "azurerm_key_vault" "kvault" {
  name                = "kvaultmv1310620202"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "get",
    ]

    secret_permissions = [
      "get",
    ]
  }
}

resource "azurerm_linux_virtual_machine" "vm1" {
  name                = "vm1"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  network_interface_ids = [
    azurerm_network_interface.nic1.id,
  ]

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    name              = "osdisk1"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_username = "azureuser"

  admin_ssh_key {
    username   = "azureuser"
    public_key = azurerm_key_vault_secret.publicclave.value
  }
}

resource "azurerm_bastion_host" "vm1host" {
  name                = "vm1host"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  virtual_network_id = azurerm_virtual_network.vnet1.id
  subnet_id          = azurerm_subnet.AzureBastionSubnet.id
}

data "azurerm_key_vault_secret" "publicclave" {
  name         = "publicclave"
  key_vault_id = azurerm_key_vault.kvault.id
}

variable "address_space" {}
variable "address_prefixes" {}
variable "address_prefixes2" {}
variable "private_ip_address" {}
