
provider "azurerm" {
  features {}
  skip_provider_registration = true
}

data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "test" {
  name = "1-3baf3667-playground-sandbox"
}

resource "azurerm_virtual_network" "vnet1" {
  name                = "vnet1"
  location            = data.azurerm_resource_group.test.location
  resource_group_name = data.azurerm_resource_group.test.name
  address_space       = var.address_space
}

resource "azurerm_subnet" "sbnet1" {
  name                      = "sbnet1"
  resource_group_name       = data.azurerm_resource_group.test.name
  virtual_network_name      = azurerm_virtual_network.vnet1.name
  address_prefixes          = var.address_prefixes
}

resource "azurerm_network_interface" "nic1" {
  name                      = "nic1"
  location                  = data.azurerm_resource_group.test.location
  resource_group_name       = data.azurerm_resource_group.test.name

  ip_configuration {
    name                          = "config1"
    subnet_id                     = azurerm_subnet.sbnet1.id
    private_ip_address            = var.private_ip_address
    private_ip_address_allocation = "Static"
  }
}

resource "tls_private_key" "key1" {
  algorithm   = "RSA"
  rsa_bits    = 4096
}

resource "azurerm_key_vault" "kvaultmv1" {
  name                = "kvaultmv1"
  location            = data.azurerm_resource_group.test.location
  resource_group_name = data.azurerm_resource_group.test.name
  tenant_id           = data.azurerm_client_config.current.tenant_id

  sku_name = "standard"

  network_acls {
    bypass        = "AzureServices"
    default_action = "Allow"
    ip_rules      = ["188.26.198.118"]
  }

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

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

resource "azurerm_key_vault_secret" "public-clave" {
  name         = "public-clave"
  value        = tls_private_key.key1.public_key_openssh
  key_vault_id = azurerm_key_vault.kvaultmv1.id
}

resource "azurerm_key_vault_secret" "secret-clave" {
  name         = "secret-clave"
  value        = tls_private_key.key1.private_key_pem
  key_vault_id = azurerm_key_vault.kvaultmv1.id
}

data "azurerm_image" "ubuntu" {
  name                = "UbuntuServer"
  resource_group_name = data.azurerm_resource_group.test.name
}

resource "azurerm_linux_virtual_machine" "vm1" {
  name                = "vm1"
  location            = data.azurerm_resource_group.test.location
  resource_group_name = data.azurerm_resource_group.test.name
  size                = "Standard_B2s"

  storage_image_reference {
    id = data.azurerm_image.ubuntu.id
  }

  admin_username = "azureuser"

  os_disk {
    name                 = "os_disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_ssh_key {
    username = "azureuser"
    public_key = azurerm_key_vault_secret.public-clave.value
  }
}

variable "address_space" {}

variable "address_prefixes" {}

variable "private_ip_address" {}
