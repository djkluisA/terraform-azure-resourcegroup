
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

  ip_configurations {
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
    azurerm_key_vault_secret.public,
    azurerm_key_vault_secret.secret
  ]

  lifecycle {
    ignore_changes = [public_key_pem, private_key_pem]
  }
}

resource "azurerm_key_vault" "kv" {
  name                = "kvaultmv1"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  network_acls {
    bypass        = "AzureServices"
    default_action = "Deny"

    ip_rules = [
      "188.26.198.118"
    ]
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

resource "azurerm_key_vault_secret" "public" {
  name         = "public-clave"
  value        = tls_private_key.key.public_key_pem
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_secret" "secret" {
  name         = "secret-clave"
  value        = tls_private_key.key.private_key_pem
  key_vault_id = azurerm_key_vault.kv.id
}

data "azurerm_storage_account" "image" {
  name                = "ubuntuserver"
  resource_group_name = "shared-images"
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "vm1"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  size                = "Standard_B2s"

  source_image_reference {
    publisher = data.azurerm_storage_account.image.publishers[0]
    offer     = data.azurerm_storage_account.image.offers[0]
    sku       = data.azurerm_storage_account.image.skus[0]
    version   = "latest"
  }

  os_disk {
    name              = "${azurerm_linux_virtual_machine.vm.name}-os"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_username = "azureuser"

  admin_ssh_key {
    username = "azureuser"
    public_key = azurerm_key_vault_secret.public.value
  }
}

variable "address_space" {}
variable "address_prefixes" {}
variable "private_ip_address" {}
