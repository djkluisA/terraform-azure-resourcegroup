
provider "azurerm" {
  skip_provider_registration = true

  features {}
}

data "azurerm_resource_group" "rg" {
  name = "1-03efbf66-playground-sandbox"
}

data "azurerm_client_config" "current" {}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet1"
  address_space       = var.address_space
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "sbnet" {
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
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.sbnet.id
    private_ip_address            = var.private_ip_address
    private_ip_address_allocation = "Static"
  }
}

resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096

  depends_on = [
    azurerm_key_vault.kvault
  ]

  lifecycle {
    ignore_changes = [
      azurerm_key_vault_secret.publicclave,
      azurerm_key_vault_secret.secretclave
    ]
  }
}

resource "azurerm_key_vault" "kvault" {
  name                = "kvaultmv129052023"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

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

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "vm1"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  size                = "Standard_B2s"

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

  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]
}

resource "azurerm_key_vault_secret" "publicclave" {
  name         = "publicclave"
  value        = tls_private_key.key.public_key_openssh
  key_vault_id = azurerm_key_vault.kvault.id
}

resource "azurerm_key_vault_secret" "secretclave" {
  name         = "secretclave"
  value        = tls_private_key.key.private_key_pem
  key_vault_id = azurerm_key_vault.kvault.id
}

variable "address_space" {}

variable "address_prefixes" {}

variable "private_ip_address" {}
