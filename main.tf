
# Configuración del proveedor de Azure
provider "azurerm" {
  skip_provider_registration = true
  features {}
}

# Obtención del grupo de recursos
data "azurerm_resource_group" "resource-group" {
  name = "1-3baf3667-playground-sandbox"
}

# Obtención de la configuración del cliente
data "azurerm_client_config" "current" {}

# Creación de la red virtual
resource "azurerm_virtual_network" "vnet1" {
  name                = "vnet1"
  address_space       = var.address_space
  location            = data.azurerm_resource_group.resource-group.location
  resource_group_name = data.azurerm_resource_group.resource-group.name
}

# Creación de la subred virtual
resource "azurerm_subnet" "sbnet1" {
  name                  = "sbnet1"
  resource_group_name   = data.azurerm_resource_group.resource-group.name
  virtual_network_name  = azurerm_virtual_network.vnet1.name
  address_prefixes      = var.address_prefixes
}

# Creación de la interfaz de red
resource "azurerm_network_interface" "nic1" {
  name                = "nic1"
  location            = data.azurerm_resource_group.resource-group.location
  resource_group_name = data.azurerm_resource_group.resource-group.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.sbnet1.id
    private_ip_address            = var.private_ip_address
    private_ip_address_allocation = "Static"
  }
}

# Creación del recurso tls_private_key
resource "tls_private_key" "key-pair" {
  algorithm   = "RSA"
  rsa_bits    = 4096

  depends_on = [azurerm_key_vault.kvaultmv1]

  lifecycle {
    create_before_destroy = false
    ignore_changes        = []
    prevent_destroy       = false
  }
}

# Creación del key vault
resource "azurerm_key_vault" "kvaultmv1" {
  name                        = "kvaultmv1"
  resource_group_name         = data.azurerm_resource_group.resource-group.name
  location                    = data.azurerm_resource_group.resource-group.location
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  
  network_acls {
    default_action            = "Deny"
    bypass                     = "AzureServices"
    ip_rules                   = ["188.26.198.118"]
  }

  access_policy {
    tenant_id                 = data.azurerm_client_config.current.tenant_id
    object_id                 = data.azurerm_client_config.current.object_id
    secret_permissions        = ["Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"]
  }
}

# Creación de los secrets del key vault
resource "azurerm_key_vault_secret" "public-key" {
  name         = "public-clave"
  value        = tls_private_key.key-pair.public_key_pem
  key_vault_id = azurerm_key_vault.kvaultmv1.id
}

resource "azurerm_key_vault_secret" "private-key" {
  name         = "secret-clave"
  value        = tls_private_key.key-pair.private_key_pem
  key_vault_id = azurerm_key_vault.kvaultmv1.id
}

# Creación de la máquina virtual Linux
resource "azurerm_linux_virtual_machine" "vm1" {
  name                  = "vm1"
  location              = data.azurerm_resource_group.resource-group.location
  resource_group_name   = data.azurerm_resource_group.resource-group.name
  size                  = "Standard_B2s"

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  admin_username = "azureuser"

  os_disk {
    name              = "osdisk"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_ssh_key {
    username = "azureuser"
    public_key = azurerm_key_vault_secret.public-key.value
  }

  network_interface_ids = [
    azurerm_network_interface.nic1.id
  ]
}

# Declaración de variables
variable "address_space" {}
variable "address_prefixes" {}
variable "private_ip_address" {}
