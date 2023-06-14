
provider "azurerm" {
  skip_provider_registration = true

  features {}
}

data "azurerm_resource_group" "rg" {
  name = "1-52c8b3d4-playground-sandbox"
}

data "azurerm_client_config" "current" {}

resource "azurerm_virtual_network" "uno" {
  name                = "uno"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  address_space       = var.address_space
}

resource "azurerm_subnet" "sbnet1uno" {
  name                 = "sbnet1uno"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.uno.name
  address_prefixes     = var.address_prefixes
}

resource "azurerm_network_interface" "nic1cuatro" {
  name                = "nic1cuatro"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.sbnet1uno.id
    private_ip_address            = var.private_ip_address
    private_ip_address_allocation = "Static"
  }
}

resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096

  depends_on = [
    azurerm_key_vault.doskeyvault1406
  ]

  lifecycle {
    ignore_changes = [
      "private_key_pem",
      "public_key_openssh"
    ]
  }
}

resource "azurerm_key_vault" "doskeyvault1406" {
  name                = "doskeyvault1406"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

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

resource "azurerm_linux_virtual_machine" "cuatro" {
  name                = "cuatro"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  size                = "Standard_B2s"

  admin_username = "azureuser"

  admin_ssh_key {
    username   = "azureuser"
    public_key = azurerm_key_vault_secret.publicclave.value
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    name              = "osdisk"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  network_interface_ids = [
    azurerm_network_interface.nic1cuatro.id
  ]
}

resource "azurerm_public_ip" "pipbastioncuatro" {
  name                = "pipbastioncuatro"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_subnet" "AzureBastionSubnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.uno.name
  address_prefixes     = var.address_prefixes2
}

resource "azurerm_bastion_host" "cuatrohost" {
  name                = "cuatrohost"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  sku                 = "Standard"
  ip_connect_enabled  = true

  ip_configuration {
    name                          = "cuatroconnect"
    subnet_id                     = azurerm_subnet.AzureBastionSubnet.id
    public_ip_address_id          = azurerm_public_ip.pipbastioncuatro.id
  }
}

resource "azurerm_key_vault_secret" "publicclave" {
  name         = "publicclave"
  value        = tls_private_key.key.public_key_openssh
  key_vault_id = azurerm_key_vault.doskeyvault1406.id
}

resource "azurerm_key_vault_secret" "secretclave" {
  name         = "secretclave"
  value        = tls_private_key.key.private_key_pem
  key_vault_id = azurerm_key_vault.doskeyvault1406.id
}

variable "address_space" {}

variable "address_prefixes" {}

variable "address_prefixes2" {}

variable "private_ip_address" {}
