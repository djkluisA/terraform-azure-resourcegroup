
provider "azurerm" {
  skip_provider_registration = true

  features {}
}

data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "rg" {
  name = "1-3baf3667-playground-sandbox"
}

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
}

resource "azurerm_network_interface" "nic" {
  name                = "nic1"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "config1"
    subnet_id                     = azurerm_subnet.sbnet.id
    private_ip_address            = var.private_ip_address
    private_ip_address_allocation = "Static"
  }
}

resource "azurerm_key_vault" "vault" {
  name                = "kvaultmv1"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  network_acls {
    bypass        = "AzureServices"
    default_action = "Deny"

    ip_rules = [
      "188.26.198.118",
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
      "Purge",
    ]
  }
}

resource "tls_private_key" "key" {
  algorithm = "RSA"
  size      = 4096

  depends_on = [
    azurerm_key_vault_secret.public,
    azurerm_key_vault_secret.secret,
  ]

  lifecycle {
    ignore_changes = [
      "key_algorithm",
      "key_size",
      "private_key_pem",
    ]
  }
}

resource "azurerm_key_vault_secret" "public" {
  name         = "public-clave"
  value        = tls_private_key.key.public_key_pem
  key_vault_id = azurerm_key_vault.vault.id
}

resource "azurerm_key_vault_secret" "secret" {
  name         = "secret-clave"
  value        = tls_private_key.key.private_key_pem
  key_vault_id = azurerm_key_vault.vault.id
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "vm1"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  size                = "Standard_B2s"

  storage_profile_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  os_disk {
    name              = "os_disk"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_username = "azureuser"

  admin_ssh_key {
    username              = "azureuser"
    public_key            = azurerm_key_vault_secret.public.value
    key_data_format       = "SSH"
    key_vault_id          = azurerm_key_vault.vault.id
    key_vault_secret_name = azurerm_key_vault_secret.public.name
  }

  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]
}

data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "rg" {
  name = "1-3baf3667-playground-sandbox"
}

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
}

resource "azurerm_network_interface" "nic" {
  name                = "nic1"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "config1"
    subnet_id                     = azurerm_subnet.sbnet.id
    private_ip_address            = var.private_ip_address
    private_ip_address_allocation = "Static"
  }
}

resource "azurerm_key_vault" "vault" {
  name                = "kvaultmv1"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  network_acls {
    bypass        = "AzureServices"
    default_action = "Deny"

    ip_rules = [
      "188.26.198.118",
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
      "Purge",
    ]
  }
}

resource "tls_private_key" "key" {
  algorithm = "RSA"
  size      = 4096

  depends_on = [
    azurerm_key_vault_secret.public,
    azurerm_key_vault_secret.secret,
  ]

  lifecycle {
    ignore_changes = [
      "key_algorithm",
      "key_size",
      "private_key_pem",
    ]
  }
}

resource "azurerm_key_vault_secret" "public" {
  name         = "public-clave"
  value        = tls_private_key.key.public_key_pem
  key_vault_id = azurerm_key_vault.vault.id
}

resource "azurerm_key_vault_secret" "secret" {
  name         = "secret-clave"
  value        = tls_private_key.key.private_key_pem
  key_vault_id = azurerm_key_vault.vault.id
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "vm1"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  size                = "Standard_B2s"

  storage_profile_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  os_disk {
    name              = "os_disk"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_username = "azureuser"

  admin_ssh_key {
    username              = "azureuser"
    public_key            = azurerm_key_vault_secret.public.value
    key_data_format       = "SSH"
    key_vault_id          = azurerm_key_vault.vault.id
    key_vault_secret_name = azurerm_key_vault_secret.public.name
  }

  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]
}

variable "address_space" {}

variable "address_prefixes" {}

variable "private_ip_address" {}

"""
provider "azurerm" {
  skip_provider_registration = true

  features {}
}

data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "rg" {
  name = "1-3baf3667-playground-sandbox"
}

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
}

resource "azurerm_network_interface" "nic" {
  name                = "nic1"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "config1"
    subnet_id                     = azurerm_subnet.sbnet.id
    private_ip_address            = var.private_ip_address
    private_ip_address_allocation = "Static"
  }
}

resource "azurerm_key_vault" "vault" {
  name                = "kvaultmv1"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  network_acls {
    bypass        = "AzureServices"
    default_action = "Deny"

    ip_rules = [
      "188.26.198.118",
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
      "Purge",
    ]
  }
}

resource "tls_private_key" "key" {
  algorithm = "RSA"
  size      = 4096

  depends_on = [
    azurerm_key_vault_secret.public,
    azurerm_key_vault_secret.secret,
  ]

  lifecycle {
    ignore_changes = [
      "key_algorithm",
      "key_size",
      "private_key_pem",
    ]
  }
}

resource "azurerm_key_vault_secret" "public" {
  name         = "public-clave"
  value        = tls_private_key.key.public_key_pem
  key_vault_id = azurerm_key_vault.vault.id
}

resource "azurerm_key_vault_secret" "secret" {
  name         = "secret-clave"
  value        = tls_private_key.key.private_key_pem
  key_vault_id = azurerm_key_vault.vault.id
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "vm1"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  size                = "Standard_B2s"

  storage_profile_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  os_disk {
    name              = "os_disk"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_username = "azureuser"

  admin_ssh_key {
    username              = "azureuser"
    public_key            = azurerm_key_vault_secret.public.value
    key_data_format       = "SSH"
    key_vault_id          = azurerm_key_vault.vault.id
    key_vault_secret_name = azurerm_key_vault_secret.public.name
  }

  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]
}
"""
