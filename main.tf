
provider "azurerm" {
  skip_provider_registration = true

  features {}
}

data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "rg" {
  name = "1-52c8b3d4-playground-sandbox"
}

resource "azurerm_virtual_network" "uno" {
  name                = "uno"
  address_space       = [var.address_space]
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "sbnet1uno" {
  name                 = "sbnet1uno"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.uno.name
  address_prefixes     = [var.address_prefixes]
}

resource "azurerm_network_interface" "nic1cuatro" {
  name                = "nic1cuatro"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.sbnet1uno.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.private_ip_address
  }
}

resource "azurerm_tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096

  dynamic "secret" {
    for_each = ["public", "private"]
    content {
      name      = "${secret.value}clave"
      value     = azurerm_tls_private_key.key[secret.value]
      key_vault_id = azurerm_key_vault.doskeyvault1406.id
    }
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
      "Purge",
    ]
  }
}

resource "azurerm_linux_virtual_machine" "cuatro" {
  name                = "cuatro"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  size                = "Standard_B2s"

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    name              = "osdiskcuatro"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  network_interface_ids = [azurerm_network_interface.nic1cuatro.id]

  admin_username = "azureuser"

  admin_ssh_key {
    username   = "azureuser"
    public_key = azurerm_key_vault_secret.publicclave.value
  }
}

resource "azurerm_bastion_host" "cuatrohost" {
  name                = "cuatrohost"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  sku                 = "Standard"
  ip_configuration {
    name                          = "cuatroconnect"
    subnet_id                     = azurerm_subnet.sbnet1uno.id
    public_ip_address_id          = azurerm_public_ip.pipbastioncuatro.id
  }
}

resource "azurerm_public_ip" "pipbastioncuatro" {
  name                = "pipbastioncuatro"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

variable "address_space" {}

variable "address_prefixes" {}

variable "address_prefixes2" {}

variable "private_ip_address" {}

