
provider "azurerm" {
  skip_provider_registration = true

  features {}
}

data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "example" {
  name = "1-52c8b3d4-playground-sandbox"
}

resource "azurerm_virtual_network" "example" {
  name                = "example-network"
  address_space       = var.address_space
  location            = data.azurerm_resource_group.example.location
  resource_group_name = data.azurerm_resource_group.example.name
}

resource "azurerm_subnet" "example" {
  name                 = "example-subnet"
  resource_group_name  = data.azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = var.address_prefixes
}

resource "azurerm_network_interface" "example" {
  name                = "example-nic"
  location            = data.azurerm_resource_group.example.location
  resource_group_name = data.azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.private_ip_address
  }
}

resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_key_vault" "example" {
  name                = "example-keyvault"
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

resource "azurerm_linux_virtual_machine" "example" {
  name                = "example-vm"
  location            = data.azurerm_resource_group.example.location
  resource_group_name = data.azurerm_resource_group.example.name
  size                = "Standard_B2s"
  admin_username      = "azureuser"
  network_interface_ids = [
    azurerm_network_interface.example.id,
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = azurerm_key_vault_secret.example_public_key.value
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    name              = "example-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "example-vm"
    admin_username = "azureuser"
    linux_configuration {
      disable_password_authentication = true
    }
  }
}

resource "azurerm_key_vault_secret" "example_public_key" {
  name         = "example-public-key"
  value        = tls_private_key.example.public_key_pem
  key_vault_id = azurerm_key_vault.example.id
}

resource "azurerm_bastion_host" "example" {
  name                = "example-bastion"
  location            = data.azurerm_resource_group.example.location
  resource_group_name = data.azurerm_resource_group.example.name
  ip_configurations = [
    {
      name                          = "example-connect"
      subnet_id                     = azurerm_subnet.example.id
      public_ip_address_id          = azurerm_public_ip.example.id
      private_ip_address_allocation = "Dynamic"
    }
  ]

  target_virtual_network_ids = [
    azurerm_virtual_network.example.id,
  ]
}

resource "azurerm_public_ip" "example" {
  name                = "example-public-ip"
  location            = data.azurerm_resource_group.example.location
  resource_group_name = data.azurerm_resource_group.example.name
  allocation_method   = "Static"
}

variable "address_space" {}

variable "address_prefixes" {}

variable "address_prefixes2" {}

variable "private_ip_address" {}
