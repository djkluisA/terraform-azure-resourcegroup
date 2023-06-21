hcl
 {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
  skip_provider_registration = true
  features {}
}

variable "address_space" {}
variable "address_prefixes" {}
variable "address_prefixes2" {}
variable "private_ip_address" {}

data "azurerm_resource_group" "example" {
  name = "1-add4c5fe-playground-sandbox"
}

data "azurerm_client_config" "current" {}

resource "azurerm_virtual_network" "vnetopenai" {
  name                = "vnetopenai"
  address_space       = [var.address_space]
  location            = data.azurerm_resource_group.example.location
  resource_group_name = data.azurerm_resource_group.example.name
}

resource "azurerm_subnet" "sbnet1vnetopenai" {
  name                 = "sbnet1vnetopenai"
  resource_group_name  = data.azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.vnetopenai.name
  address_prefixes     = [var.address_prefixes]
}

resource "azurerm_network_interface" "nic1vmopenai" {
  name                = "nic1vmopenai"
  location            = data.azurerm_resource_group.example.location
  resource_group_name = data.azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.sbnet1vnetopenai.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.private_ip_address
  }
}

resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_key_vault" "keyvaultopenai" {
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
      "Purge",
    ]
  }
}

resource "azurerm_key_vault_secret" "publicclave" {
  name         = "publicclave"
  value        = tls_private_key.example.public_key_pem
  key_vault_id = azurerm_key_vault.keyvaultopenai.id
}

resource "azurerm_key_vault_secret" "secretclave" {
  name         = "secretclave"
  value        = tls_private_key.example.private_key_pem
  key_vault_id = azurerm_key_vault.keyvaultopenai.id
}

resource "azurerm_linux_virtual_machine" "vmopenai" {
  name                = "vmopenai"
  resource_group_name = data.azurerm_resource_group.example.name
  location            = data.azurerm_resource_group.example.location
  size                = "Standard_B2s"
  network_interface_ids = [
    azurerm_network_interface.nic1vmopenai.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name  = "vmopenai"
  admin_username = "azureuser"

  admin_ssh_key {
    username   = "azureuser"
    public_key = azurerm_key_vault_secret.publicclave.value
  }
}

resource "azurerm_public_ip" "pipbastionvmopenai" {
  name                = "pipbastionvmopenai"
  location            = data.azurerm_resource_group.example.location
  resource_group_name = data.azurerm_resource_group.example.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_subnet" "AzureBastionSubnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = data.azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.vnetopenai.name
  address_prefixes     = [var.address_prefixes2]
}

resource "azurerm_bastion_host" "vmopenaihost" {
  name                = "vmopenaihost"
  location            = data.azurerm_resource_group.example.location
  resource_group_name = data.azurerm_resource_group.example.name

  ip_configuration {
    name                 = "vmopenaiconnect"
    subnet_id            = azurerm_subnet.AzureBastionSubnet.id
    public_ip_address_id = azurerm_public_ip.pipbastionvmopenai.id
  }
}
