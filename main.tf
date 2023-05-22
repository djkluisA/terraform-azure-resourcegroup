
provider "azurerm" {
  features {}
  skip_provider_registration = true
}

data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "rg" {
  name = "1-3baf3667-playground-sandbox"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet1"
  address_space       = ["10.0.0.0/16"]
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "sbnet" {
  name                 = "sbnet1"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "nic" {
  name                = "nic1"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.sbnet.id
    private_ip_address            = var.private_ip_address
    private_ip_address_allocation = "Static"
  }
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_key_vault" "key_vault" {
  name                        = "kvaultmv1"
  location                    = data.azurerm_resource_group.rg.location
  resource_group_name         = data.azurerm_resource_group.rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id
    secret_permissions = [
      "Get", "List", "Set", 
      "Delete", "Recover", "Backup", 
      "Restore", "Purge"
    ]
  }

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  
    ip_rules = [
      "188.26.198.118"
    ]
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "vm1"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  size                = "Standard_B2s"

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
    username   = "azureuser"
    public_key = azurerm_key_vault_secret.public_key.value
  }

  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  depends_on = [
    azurerm_key_vault_secret.public_key,
    azurerm_key_vault_secret.secret_key
  ]
}

resource "azurerm_key_vault_secret" "public_key" {
  name         = "public-clave"
  value        = tls_private_key.private_key.public_key_openssh
  key_vault_id = azurerm_key_vault.key_vault.id
}

resource "azurerm_key_vault_secret" "secret_key" {
  name         = "secret-clave"
  value        = tls_private_key.private_key.private_key_pem
  key_vault_id = azurerm_key_vault.key_vault.id
} 

# Data resources
data "azurerm_subscription" "current" {}

data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "rg" {
  name = "1-3baf3667-playground-sandbox"
}

# Variables
variable "address_space" {}

variable "address_prefixes" {}

variable "private_ip_address" {}

# Outputs
output "vm_private_ip_address" {
  value = azurerm_network_interface.nic.private_ip_address
}

output "vm_ssh_command" {
  value = "ssh azureuser@${azurerm_network_interface.nic.private_ip_address}"
}
