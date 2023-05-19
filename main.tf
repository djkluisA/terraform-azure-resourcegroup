
provider "azurerm" {
  skip_provider_registration = true
  features {}
}

data "azurerm_client_config" "current" {}

variable "address_space" {}
variable "address_prefixes" {}
variable "private_ip_address" {}

resource "azurerm_resource_group" "rg" {
  name     = "1-3baf3667-playground-sandbox"
  location = "eastus"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet1"
  address_space       = var.address_space
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "sbnet" {
  name                 = "sbnet1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.address_prefixes
}

resource "azurerm_network_interface" "nic" {
  name                = "nic1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "config1"
    subnet_id                     = azurerm_subnet.sbnet.id
    private_ip_address            = var.private_ip_address
    private_ip_address_allocation = "Static"
    primary                       = true
  }
}

resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096

  depends_on = [
    azurerm_resource_group.rg
  ]
}

resource "azurerm_key_vault" "kv" {
  name                = "kvaultmv1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku_name = "standard"

  network_acls {
    default_action = "Deny"

    bypass = "AzureServices"

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

  lifecycle {
    ignore_changes = [
      "access_policy"
    ]
  }
}

resource "azurerm_key_vault_secret" "public_key" {
  name      = "public-clave"
  value     = tls_private_key.key.public_key_openssh
  vault_uri = azurerm_key_vault.kv.vault_uri
}

resource "azurerm_key_vault_secret" "secret_key" {
  name      = "secret-clave"
  value     = tls_private_key.key.private_key_pem
  vault_uri = azurerm_key_vault.kv.vault_uri
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "vm1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_B2s"

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  os_disk {
    name                 = "osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_username = "azureuser"

  admin_ssh_key {
    username   = "azureuser"
    public_key = azurerm_key_vault_secret.public_key.value
  }
}
