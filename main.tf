
provider "azurerm" {
  skip_provider_registration = true

  features {}
}

data "azurerm_resource_group" "rg" {
  name = "1-2732064a-playground-sandbox"
}

data "azurerm_client_config" "current" {}

resource "azurerm_virtual_network" "vnet" {
  name                = "myvnet"
  address_space       = var.address_space
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "mysubnet"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.address_prefixes
}

resource "azurerm_network_interface" "nic" {
  name                = "myNIC"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "myNICConfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.private_ip_address
  }
}

resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_key_vault" "vault" {
  name                = "myVault"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  sku_name = "standard"

  tenant_id = data.azurerm_client_config.current.tenant_id
  enabled_for_disk_encryption = true

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id

    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "create",
      "get",
      "list",
      "delete",
      "backup",
      "restore"
    ]

    secret_permissions = [
      "get",
      "list",
      "set",
      "delete",
      "backup",
      "restore"
    ]
  }
}

resource "azurerm_virtual_machine" "vm" {
  name                  = "myVM"
  location              = data.azurerm_resource_group.rg.location
  resource_group_name   = data.azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic.id]

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "myOsDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
  }

  os_profile {
    computer_name  = "myVM"
    admin_username = "azureuser"

    admin_ssh_key {
      username   = "azureuser"
      public_key = azurerm_key_vault_secret.public_key.value
    }
  }

  os_profile_linux_config {
    disable_password_authentication = true
  }

  tags = {
    environment = "dev"
  }
}

resource "azurerm_bastion_host" "bastion" {
  name                = "myBastion"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name      = "myBastionConfig"
    subnet_id = azurerm_subnet.subnet.id
    public_ip_address_id = ""
  }
}

data "azurerm_key_vault_secret" "public_key" {
  name         = "publicclave"
  key_vault_id = azurerm_key_vault.vault.id
}

variable "address_space" {}
variable "address_prefixes" {}
variable "address_prefixes2" {}
variable "private_ip_address" {}
