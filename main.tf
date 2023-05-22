
provider "azurerm" {
  features {}
  skip_provider_registration = true
}

data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "rg" {
  name = "1-3baf3667-playground-sandbox"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet1"
  address_space       = var.address_space
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "sbnet1"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.address_prefixes
}

resource "azurerm_network_interface" "nic" {
  name                = "nic1"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "nicconfig1"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address            = var.private_ip_address
    private_ip_address_allocation = "Static"
  }
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
  size      = 4096
}

resource "azurerm_key_vault" "kv" {
  name                = "kvaultmv1"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  
  sku_name = "standard"

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules       = ["188.26.198.118"]
  }

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
      "Recover",
      "Backup",
      "Restore",
      "Purge"
    ]
  }
}

data "azurerm_key_vault_secret" "public_key" {
  name         = "public-clave"
  key_vault_id = azurerm_key_vault.kv.id
}

data "azurerm_key_vault_secret" "private_key" {
  name         = "secret-clave"
  key_vault_id = azurerm_key_vault.kv.id
}

data "azurerm_virtual_machine_image" "ubuntu_server" {
  most_recent = true

  publisher = "Canonical"
  offer     = "UbuntuServer"
  sku       = "18.04-LTS"
}

resource "azurerm_linux_virtual_machine" "vm" {
  name              = "vm1"
  location          = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  size              = "Standard_B2s"

  admin_username = "azureuser"

  admin_ssh_key {
    username   = "azureuser"
    public_key = data.azurerm_key_vault_secret.public_key.value
  }

  source_image_reference {
    publisher = data.azurerm_virtual_machine_image.ubuntu_server.publisher
    offer     = data.azurerm_virtual_machine_image.ubuntu_server.offer
    sku       = data.azurerm_virtual_machine_image.ubuntu_server.sku
    version   = "latest"
  }

  os_disk {
    name              = "osdisk"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}

variable "address_space" {}

variable "address_prefixes" {}

variable "private_ip_address" {}
