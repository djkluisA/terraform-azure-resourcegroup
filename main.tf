
# Configuración del proveedor de Azure
provider "azurerm" {
  skip_provider_registration = true

  features {}
}

# Datos del grupo de recursos
data "azurerm_resource_group" "current" {
  name = "1-3baf3667-playground-sandbox"
}

# Datos del cliente de Azure
data "azurerm_client_config" "current" {}

# Variables
variable "address_space" {}
variable "address_prefixes" {}
variable "private_ip_address" {}

# Recurso de red virtual
resource "azurerm_virtual_network" "vnet1" {
  name                = "vnet1"
  address_space       = var.address_space
  location            = data.azurerm_resource_group.current.location
  resource_group_name = data.azurerm_resource_group.current.name
}

# Subred virtual
resource "azurerm_subnet" "sbnet1" {
  name                 = "sbnet1"
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = var.address_prefixes
}

# Recurso de clave privada TLS
resource "tls_private_key" "keypair" {
  algorithm = "RSA"
  size      = 4096

  depends_on = [
    azurerm_key_vault_secret.public,
    azurerm_key_vault_secret.secret
  ]
}

# Key Vault
resource "azurerm_key_vault" "kvaultmv1" {
  name                = "kvaultmv1"
  location            = data.azurerm_resource_group.current.location
  resource_group_name = data.azurerm_resource_group.current.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules       = ["188.26.198.118"]
  }

  access_policy {
    tenant_id         = data.azurerm_client_config.current.tenant_id
    object_id         = data.azurerm_client_config.current.object_id
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
    azurerm_subnet.sbnet1
  ]
}

# Secretos del Key Vault
resource "azurerm_key_vault_secret" "public" {
  name         = "public-clave"
  value        = tls_private_key.keypair.public_key_pem
  key_vault_id = azurerm_key_vault.kvaultmv1.id
}

resource "azurerm_key_vault_secret" "secret" {
  name         = "secret-clave"
  value        = tls_private_key.keypair.private_key_pem
  key_vault_id = azurerm_key_vault.kvaultmv1.id
}

# Interfaz de red
resource "azurerm_network_interface" "nic1" {
  name                = "nic1"
  location            = data.azurerm_resource_group.current.location
  resource_group_name = data.azurerm_resource_group.current.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.sbnet1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.private_ip_address
  }
}

# Máquina virtual
resource "azurerm_linux_virtual_machine" "vm1" {
  name                = "vm1"
  location            = data.azurerm_resource_group.current.location
  resource_group_name = data.azurerm_resource_group.current.name
  size                = "Standard_B2s"

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

  admin_username = "azureuser"

  admin_ssh_key {
    username   = "azureuser"
    public_key = azurerm_key_vault_secret.public.value
  }

  depends_on = [
    azurerm_network_interface.nic1
  ]
}
