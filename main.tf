
provider "azurerm" {
  skip_provider_registration = true
  features {}
}

data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "rg" {
  name = "1-3baf3667-playground-sandbox"
}

resource "azure_virtual_network" "vnet1" {
  name                = "vnet1"
  location            = data.azurerm_resource_group.rg.location
  address_space       = var.address_space
}

resource "azure_subnet" "sbnet1" {
  name                  = "sbnet1"
  virtual_network_name  = azure_virtual_network.vnet1.name
  address_prefixes      = var.address_prefixes
}

resource "azure_network_interface" "nic1" {
  name                        = "nic1"
  location                    = data.azurerm_resource_group.rg.location

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azure_subnet.sbnet1.id
    private_ip_address            = var.private_ip_address
    private_ip_allocation_method  = "Static"
  }
}

resource "tls_private_key" "key" {
  algorithm   = "RSA"
  rsa_bits    = 4096
}

resource "azurerm_key_vault" "kvaultmv1" {
  name                        = "kvaultmv1"
  location                    = data.azurerm_resource_group.rg.location
  resource_group_name         = data.azurerm_resource_group.rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"

  network_acls {
    default_action    = "Deny"
    bypass            = "AzureServices"
    ip_rules          = ["188.26.198.118"]
  }

  access_policy {
    tenant_id             = data.azurerm_client_config.current.tenant_id
    object_id             = data.azurerm_client_config.current.object_id
    secret_permissions    = ["Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"]
  }
}

resource "azurerm_key_vault_secret" "public" {
  name         = "public-clave"
  value        = tls_private_key.key.public_key_pem
  key_vault_id = azurerm_key_vault.kvaultmv1.id
}

resource "azurerm_key_vault_secret" "secret" {
  name         = "secret-clave"
  value        = tls_private_key.key.private_key_pem
  key_vault_id = azurerm_key_vault.kvaultmv1.id
}

resource "azurerm_linux_virtual_machine" "vm1" {
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

  admin_username = "azureuser"

  os_disk {
    name            = "osdisk1"
    storage_account_type = "Standard_LRS"
    caching         = "ReadWrite"
  }

  admin_ssh_key {
    username            = "azureuser"
    public_key          = azurerm_key_vault_secret.public.value
  }
}

variable "address_space" {}

variable "address_prefixes" {}

variable "private_ip_address" {}
