
provider "azurerm" {
  skip_provider_registration = true

  features {}

}

data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "rg" {
  name = "1-3baf3667-playground-sandbox"
}

resource "azurerm_virtual_network" "vnet1" {
  name                = "vnet1"
  address_space       = var.address_space
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "sbnet1" {
  name                 = "sbnet1"
  address_prefixes     = var.address_prefixes
  virtual_network_name = azurerm_virtual_network.vnet1.name
  resource_group_name  = data.azurerm_resource_group.rg.name
}

resource "azurerm_network_interface" "nic1" {
  name                = "nic1"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.sbnet1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.private_ip_address
  }
}

resource "tls_private_key" "example" {
  algorithm   = "RSA"
  rsa_bits    = 4096
}

resource "azurerm_key_vault" "kvaultmv1" {
  name                       = "kvaultmv1"
  location                   = data.azurerm_resource_group.rg.location
  resource_group_name        = data.azurerm_resource_group.rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  
  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules       = ["188.26.198.118"]
  }

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
      "Recover",
      "Backup",
      "Restore",
      "Purge"
    ]

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

resource "azurerm_linux_virtual_machine" "vm1" {
  name                             = "vm1"
  location                         = data.azurerm_resource_group.rg.location
  resource_group_name              = data.azurerm_resource_group.rg.name
  size                             = "Standard_B2s"
  admin_username                   = "azureuser"
  network_interface_ids            = [azurerm_network_interface.nic1.id]
  management_mode                  = "Auto"
  source_image_reference {
    publisher                       = "Canonical"
    offer                           = "UbuntuServer"
    sku                             = "16.04-LTS"
    version                         = "latest"
  }
  os_disk {
    name                            = "osdisk_vm1"
    caching                         = "ReadWrite"
    storage_account_type            = "Standard_LRS"
  }
  admin_ssh_key {
    username                        = "azureuser"
    public_key                      = azurerm_key_vault_secret.public_clave.value
  }
}

resource "azurerm_key_vault_secret" "public_clave" {
  name                             = "public-clave"
  value                            = tls_private_key.example.public_key_pem
  key_vault_id                     = azurerm_key_vault.kvaultmv1.id
}

resource "azurerm_key_vault_secret" "secret_clave" {
  name                             = "secret-clave"
  value                            = tls_private_key.example.private_key_pem
  key_vault_id                     = azurerm_key_vault.kvaultmv1.id
}

variable "address_space" {}

variable "address_prefixes" {}

variable "private_ip_address" {}
