
provider "azurerm" {
  skip_provider_registration = true
  features {}
}

data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "rg" {
  name = "1-3baf3667-playground-sandbox"
}

variable "address_space" {
  type = list(string)
}

variable "address_prefixes" {
  type = list(string)
}

variable "private_ip_address" {}

resource "azurerm_virtual_network" "vnet1" {
  name                = "vnet1"
  address_space       = var.address_space
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "sbnet1" {
  name                 = "sbnet1"
  address_prefixes     = var.address_prefixes
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
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

resource "tls_private_key" "keyvault" {
  algorithm = "RSA"
  rsa_bits  = 4096

  depends_on = [
    azurerm_key_vault.kv
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "azurerm_key_vault" "kv" {
  name                        = "kvaultmv1"
  location                    = data.azurerm_resource_group.rg.location
  resource_group_name         = data.azurerm_resource_group.rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  soft_delete_enabled         = false
  purge_protection_enabled    = true
  network_acls {
    default_action            = "Deny"
    bypass                    = "AzureServices"
    ip_rules                  = ["188.26.198.118/32"]
  }
}

resource "azurerm_key_vault_secret" "public-key" {
  name         = "public-clave"
  value        = tls_private_key.keyvault.public_key_openssh
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_secret" "secret-key" {
  name         = "secret-clave"
  value        = tls_private_key.keyvault.private_key_pem
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_linux_virtual_machine" "vm1" {
  name                = "vm1"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  size                = "Standard_B2s"

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  os_disk {
    name              = "vm1-osdisk"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_username = "azureuser"

  admin_ssh_key {
    username  = "azureuser"
    public_key = azurerm_key_vault_secret.public-key.value
  }

  depends_on = [
    azurerm_network_interface.nic1,
    azurerm_key_vault.kv
  ]
}
