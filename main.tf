
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
  location            = data.azurerm_resource_group.rg.location
  address_space       = [var.address_space]
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "sbnet" {
  name                 = "sbnet1"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = data.azurerm_resource_group.rg.name
  address_prefixes     = [var.address_prefixes]
}

resource "azurerm_network_interface" "nic" {
  name                = "nic1"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "nicconfig1"
    subnet_id                     = azurerm_subnet.sbnet.id
    private_ip_address            = var.private_ip_address
    private_ip_address_allocation = "Static"
  }
}

resource "tls_private_key" "private_key" {
  algorithm   = "RSA"
  rsa_bits    = 4096
  depends_on  = [tls_private_key.private_key]
  lifecycle   = { ignore_changes = [public_key_openssh, public_key_pem, pgp_key] }
}

resource "azurerm_key_vault" "kv" {
  name                = "kvaultmv1"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  network_acls {
    bypass         = "AzureServices"
    default_action = "Deny"
    ip_rules       = ["188.26.198.118"]
  }

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions    = ["Get"]
    secret_permissions = ["Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"]
  }

  secret {
    name         = "public-clave"
    value        = tls_private_key.private_key.public_key_pem
    content_type = "application/x-pem-file"
  }

  secret {
    name         = "secret-clave"
    value        = tls_private_key.private_key.private_key_pem
    content_type = "application/x-pem-file"
  }
}

data "azurerm_virtual_machine_image" "image" {
  publisher = "Canonical"
  offer     = "UbuntuServer"
  sku       = "16.04-LTS"
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "vm1"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  size                = "Standard_B2s"

  storage_image_reference {
    publisher = data.azurerm_virtual_machine_image.image.publisher
    offer     = data.azurerm_virtual_machine_image.image.offer
    sku       = data.azurerm_virtual_machine_image.image.sku
    version   = "latest"
  }

  os_disk {
    name              = "osdisk"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_username = "azureuser"

  admin_ssh_key {
    username   = "azureuser"
    public_key = azurerm_key_vault.kv.get_secret("public-clave").value
  }

  depends_on = [
    azurerm_network_interface.nic,
    azurerm_key_vault.kv,
  ]
}
