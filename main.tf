
provider "azurerm" {
  skip_provider_registration = true

  features {}
}

data "azurerm_resource_group" "rg" {
  name = "1-2732064a-playground-sandbox"
}

data "azurerm_client_config" "current" {}

resource "azurerm_virtual_network" "vnet" {
  name                = "myvnet"
  address_space       = var.address_space
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  subnet {
    name           = "mysubnet"
    address_prefix = var.address_prefixes
  }

  subnet {
    name           = "mysubnet2"
    address_prefix = var.address_prefixes2
  }
}

resource "azurerm_network_interface" "nic" {
  name                = "my-nic"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "my-ip-config"
    subnet_id                     = azurerm_virtual_network.vnet.subnet[0].id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.private_ip_address
  }
}

resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_key_vault" "kv" {
  name                = "doskeyvault1406"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  sku_name = "standard"

  tenant_id = data.azurerm_client_config.current.tenant_id
  enabled_for_disk_encryption = true
  soft_delete_enabled = null
  purge_protection_enabled = true

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id

    key_permissions = [
      "create",
      "get",
      "list",
      "delete",
      "backup",
      "restore"
    ]

    secret_permissions = [
      "get",
      "list",
      "set",
      "delete",
      "backup",
      "restore"
    ]

    certificate_permissions = [
      "get",
      "list",
      "delete",
      "create",
      "import",
      "update",
      "managecontacts",
      "getissuers",
      "listissuers",
      "setissuers",
      "deleteissuers",
      "manageissuers",
      "recover"
    ]

    object_id = data.azurerm_client_config.current.object_id
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "my-vm"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  size                = "Standard_B2s"
  admin_username      = "azureuser"

  admin_ssh_key {
    username   = "azureuser"
    public_key = azurerm_key_vault_secret.public_key.value
  }

  os_disk {
    name              = "my-os-disk"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]
}

resource "azurerm_bastion_host" "bastion" {
  name                = "my-bastion"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name      = "my-ip-config"
    subnet_id = azurerm_virtual_network.vnet.subnet[0].id
  }
}

variable "address_space" {}
variable "address_prefixes" {}
variable "address_prefixes2" {}
variable "private_ip_address" {}
