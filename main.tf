
provider "azurerm" {
  skip_provider_registration = true

  features {}
}

data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "current" {
  name = "1-3baf3667-playground-sandbox"
}

resource "azurerm_virtual_network" "vnet1" {
  name                = "vnet1"
  resource_group_name = data.azurerm_resource_group.current.name
  location            = data.azurerm_resource_group.current.location
  address_space       = [var.address_space]
}

resource "azurerm_subnet" "sbnet1" {
  name                 = "sbnet1"
  resource_group_name  = data.azurerm_resource_group.current.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = [var.address_prefixes]
}

resource "azurerm_network_interface" "nic1" {
  name                = "nic1"
  resource_group_name = data.azurerm_resource_group.current.name

  ip_configuration {
    name                          = "nic1-config"
    subnet_id                     = azurerm_subnet.sbnet1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.private_ip_address
  }
}

resource "tls_private_key" "keyvault" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_key_vault" "kvaultmv1" {
  name                = "kvaultmv1"
  location            = data.azurerm_resource_group.current.location
  resource_group_name = data.azurerm_resource_group.current.name
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
    tenant_id     = data.azurerm_client_config.current.tenant_id
    object_id     = data.azurerm_client_config.current.object_id
    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
      "Recover",
      "Backup",
      "Restore",
      "Purge",
    ]
  }

  depends_on = [
    tls_private_key.keyvault
  ]
}

locals {
  ssh_public_key = azurerm_key_vault_secret.public_key.value
}

data "azurerm_key_vault_secret" "public_key" {
  name         = "public-clave"
  key_vault_id = azurerm_key_vault.kvaultmv1.id
}

data "azurerm_key_vault_secret" "private_key" {
  name         = "secret-clave"
  key_vault_id = azurerm_key_vault.kvaultmv1.id
}

resource "azurerm_linux_virtual_machine" "vm1" {
  name                = "vm1"
  location            = data.azurerm_resource_group.current.location
  resource_group_name = data.azurerm_resource_group.current.name
  size                = "Standard_B2s"

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    name              = "vm1-osdisk"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_username = "azureuser"

  admin_ssh_key {
    username   = "azureuser"
    public_key = local.ssh_public_key
  }

  depends_on = [
    azurerm_network_interface.nic1
  ]
}
