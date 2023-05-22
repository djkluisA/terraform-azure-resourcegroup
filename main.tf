
provider "azurerm" {
  features {}
  skip_provider_registration = true
}

data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "rg" {
  name = "1-3baf3667-playground-sandbox"
}

resource "tls_private_key" "key" {
  algorithm = "RSA"
  size      = 4096
}

resource "azurerm_key_vault" "kv" {
  name                = "kvaultmv1"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  tenant_id = data.azurerm_client_config.current.tenant_id
  sku_name  = "standard"

  network_acls {
    bypass        = "AzureServices"
    default_action = "Deny"

    ip_rules = [
      "188.26.198.118"
    ]
  }

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

  depends_on = [
    tls_private_key.key
  ]
}

resource "azurerm_key_vault_secret" "public" {
  name         = "public-clave"
  value        = tls_private_key.key.public_key_pem
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_secret" "secret" {
  name         = "secret-clave"
  value        = tls_private_key.key.private_key_pem
  key_vault_id = azurerm_key_vault.kv.id
}

data "azurerm_network_security_group" "nsg" {
  name                = "nsg1"
  resource_group_name = data.azurerm_resource_group.rg.name
}

variable "address_space" {}

variable "address_prefixes" {}

variable "private_ip_address" {}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet1"
  address_space       = var.address_space
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "sbnet" {
  name                 = "sbnet1"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.address_prefixes

  service_endpoint_policy_id = data.azurerm_network_security_group.nsg.id
}

resource "azurerm_network_interface" "nic" {
  name                = "nic1"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.sbnet.id
    private_ip_address            = var.private_ip_address
    private_ip_address_allocation = "Static"
  }

  depends_on = [
    azurerm_subnet.sbnet
  ]
}

resource "azurerm_virtual_machine" "vm" {
  name                  = "vm1"
  location              = data.azurerm_resource_group.rg.location
  resource_group_name   = data.azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic.id]

  vm_size = "Standard_B2s"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    name                 = "osdisk1"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "vm1"
    admin_username = "azureuser"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/azureuser/.ssh/authorized_keys"
      key_data = azurerm_key_vault_secret.public.value
    }
  }

  depends_on = [
    azurerm_key_vault_secret.public,
    azurerm_key_vault_secret.secret
  ]
}
