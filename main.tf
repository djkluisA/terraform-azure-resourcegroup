
provider "azurerm" {
  features {}
  skip_provider_registration = true
}

data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "current" {
  name = "1-3baf3667-playground-sandbox"
}

resource "azurerm_virtual_network" "vnet1" {
  name                = "vnet1"
  address_space       = var.address_space
  location            = data.azurerm_resource_group.current.location
  resource_group_name = data.azurerm_resource_group.current.name
}

resource "azurerm_subnet" "sbnet1" {
  name                 = "sbnet1"
  resource_group_name  = data.azurerm_resource_group.current.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = var.address_prefixes
}

resource "azurerm_network_interface" "nic1" {
  name                = "nic1"
  location            = data.azurerm_resource_group.current.location
  resource_group_name = data.azurerm_resource_group.current.name

  ip_configuration {
    name                          = "nic1-ipconfig1"
    subnet_id                     = azurerm_subnet.sbnet1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.private_ip_address
  }
}

resource "tls_private_key" "key" {
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
    bypass               = "AzureServices"
    default_action       = "Deny"
    ip_rules             = ["188.26.198.118"]
    virtual_network_subnet_ids = [azurerm_subnet.sbnet1.id]
  }

  access_policy {
    tenant_id          = data.azurerm_client_config.current.tenant_id
    object_id          = data.azurerm_client_config.current.object_id
    secret_permissions = [
      "get",
      "list",
      "set",
      "delete",
      "recover",
      "backup",
      "restore",
      "purge",
    ]
  }
}

resource "azurerm_key_vault_secret" "kv_secret1" {
  name         = "public-clave"
  value        = tls_private_key.key.public_key_openssh
  key_vault_id = azurerm_key_vault.kvaultmv1.id
}

resource "azurerm_key_vault_secret" "kv_secret2" {
  name         = "secret-clave"
  value        = tls_private_key.key.private_key_pem
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
    name          = "osdisk1"
    caching       = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_username = "azureuser"

  admin_ssh_key {
    username   = "azureuser"
    public_key = azurerm_key_vault_secret.kv_secret1.value
  }
}

variable "address_space" {}

variable "address_prefixes" {}

variable "private_ip_address" {}
