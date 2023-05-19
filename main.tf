
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
  address_space       = ["10.0.0.0/16"]
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "sbnet1" {
  name                 = "sbnet1"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "nic1" {
  name                = "nic1"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipcfg1"
    subnet_id                     = azurerm_subnet.sbnet1.id
    private_ip_address            = "10.0.1.4"
    private_ip_address_allocation = "Static"
  }
}

resource "tls_private_key" "key" {
  algorithm   = "RSA"
  rsa_bits    = 4096
}

resource "azurerm_key_vault" "kvaultmv1" {
  name                = "kvaultmv1"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  network_acls {
    bypass               = "AzureServices"
    default_action       = "Deny"
    ip_rules             = ["188.26.198.118"]
  }

  access_policy {
    tenant_id          = data.azurerm_client_config.current.tenant_id
    object_id          = data.azurerm_client_config.current.object_id
    secret_permissions = [
      "Backup",
      "Delete",
      "Get",
      "List",
      "Purge",
      "Recover",
      "Restore",
      "Set",
    ]
  }
}

resource "azurerm_key_vault_secret" "public-clave" {
  name         = "public-clave"
  value        = tls_private_key.key.public_key_pem
  key_vault_id = azurerm_key_vault.kvaultmv1.id
}

resource "azurerm_key_vault_secret" "secret-clave" {
  name         = "secret-clave"
  value        = tls_private_key.key.private_key_pem
  key_vault_id = azurerm_key_vault.kvaultmv1.id
}

resource "azurerm_linux_virtual_machine" "vm1" {
  name                             = "vm1"
  location                         = data.azurerm_resource_group.rg.location
  resource_group_name              = data.azurerm_resource_group.rg.name
  size                             = "Standard_B2s"
  admin_username                   = "azureuser"
  computer_name                    = "ubuntuvm"
  disable_password_authentication = true

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  os_disk {
    name                  = "vm1OSDisk"
    caching               = "ReadWrite"
    storage_account_type  = "Standard_LRS"
  }

  admin_ssh_key {
    username   = "azureuser"
    public_key = azurerm_key_vault_secret.public-clave.value
  }

  network_interface_ids = [azurerm_network_interface.nic1.id]

  depends_on = [
    azurerm_network_interface.nic1,
    azurerm_key_vault_secret.public-clave,
    azurerm_key_vault_secret.secret-clave,
    azurerm_subnet.sbnet1,
    azurerm_virtual_network.vnet1,
  ]
}

