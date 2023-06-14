
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
  address_space       = var.address_space
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  subnet {
    name           = "sbnet1uno"
    address_prefix = var.address_prefixes
  }
}

resource "azurerm_network_interface" "nic1cuatro" {
  name                = "nic1cuatro"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_virtual_network.uno.subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.private_ip_address
    public_ip_address_id          = azurerm_public_ip.pipbastioncuatro.id
  }
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
}

resource "azurerm_linux_virtual_machine" "cuatro" {
  name                = "cuatro"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.nic1cuatro.id,
  ]

  os_disk {
    name              = "osdiskcuatro"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "cuatro"
    admin_username = "adminuser"
    admin_password = tls_private_key.private_key.public_key_openssh
  }
}

resource "azurerm_bastion_host" "cuatrohost" {
  name                = "cuatrohost"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  ip_configuration {
    name                          = "ipconfig1"
    public_ip_address_id          = azurerm_public_ip.pipbastioncuatro.id
    subnet_id                     = azurerm_virtual_network.uno.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
  }
}

resource "azurerm_key_vault_secret" "publicclave" {
  name         = "publicclave"
  value        = tls_private_key.private_key.public_key_openssh
  key_vault_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${data.azurerm_resource_group.rg.name}/providers/Microsoft.KeyVault/vaults/doskeyvault1406"
}

resource "azurerm_key_vault_secret" "secretclave" {
  name         = "secretclave"
  value        = tls_private_key.private_key.private_key_pem
  key_vault_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${data.azurerm_resource_group.rg.name}/providers/Microsoft.KeyVault/vaults/doskeyvault1406"
}

resource "azurerm_public_ip" "pipbastioncuatro" {
  name                = "pipbastioncuatro"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

variable "address_space" {}
variable "address_prefixes" {}
variable "address_prefixes2" {}
variable "private_ip_address" {}
