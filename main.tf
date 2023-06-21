
provider "azurerm" {
  skip_provider_registration = true

  features {}
}

data "azurerm_resource_group" "example" {
  name = "1-add4c5fe-playground-sandbox"
}

data "azurerm_client_config" "current" {}

resource "azurerm_virtual_network" "example" {
  name                = "vnetopenai"
  address_space       = var.address_space
  location            = data.azurerm_resource_group.example.location
  resource_group_name = data.azurerm_resource_group.example.name
}

resource "azurerm_subnet" "example" {
  name                 = "sbnet1vnetopenai"
  resource_group_name  = data.azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = var.address_prefixes
}

resource "azurerm_network_interface" "example" {
  name                = "nic1vmopenai"
  location            = data.azurerm_resource_group.example.location
  resource_group_name = data.azurerm_resource_group.example.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address            = var.private_ip_address
    private_ip_address_allocation = "Static"
  }
}

resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096

  depends_on = [
    azurerm_key_vault.example
  ]
}

resource "azurerm_key_vault" "example" {
  name                = "keyvaultopenai"
  location            = data.azurerm_resource_group.example.location
  resource_group_name = data.azurerm_resource_group.example.name
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

resource "azurerm_linux_virtual_machine" "example" {
  name                = "vmopenai"
  location            = data.azurerm_resource_group.example.location
  resource_group_name = data.azurerm_resource_group.example.name
  size                = "Standard_B2s"

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  admin_username = "azureuser"

  admin_ssh_key {
    username   = "azureuser"
    public_key = azurerm_key_vault_secret.example_public.value
  }

  os_disk {
    name              = "osdisk"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  network_interface_ids = [
    azurerm_network_interface.example.id
  ]
}

resource "azurerm_public_ip" "example" {
  name                = "pipbastionvmopenai"
  location            = data.azurerm_resource_group.example.location
  resource_group_name = data.azurerm_resource_group.example.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_subnet" "example_bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = data.azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = var.address_prefixes2
}

resource "azurerm_bastion_host" "example" {
  name                = "vmopenaihost"
  location            = data.azurerm_resource_group.example.location
  resource_group_name = data.azurerm_resource_group.example.name
  sku                 = "Standard"
  ip_connect_enabled  = true

  ip_configuration {
    name                          = "vmopenaiconnect"
    subnet_id                     = azurerm_subnet.example_bastion.id
    public_ip_address_id          = azurerm_public_ip.example.id
  }
}

resource "azurerm_key_vault_secret" "example_public" {
  name         = "publicclave"
  value        = tls_private_key.example.public_key_openssh
  key_vault_id = azurerm_key_vault.example.id
}

resource "azurerm_key_vault_secret" "example_secret" {
  name         = "secretclave"
  value        = tls_private_key.example.private_key_pem
  key_vault_id = azurerm_key_vault.example.id
}

variable "address_space" {}

variable "address_prefixes" {}

variable "address_prefixes2" {}

variable "private_ip_address" {}
