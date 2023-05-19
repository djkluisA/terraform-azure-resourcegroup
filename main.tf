
provider "azurerm" {
  features {}
  skip_provider_registration = true
}

data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "rg" {
  name = "1-3baf3667-playground-sandbox"
}

resource "azurerm_virtual_network" "vnet1" {
  name                = "vnet1"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "sbnet1" {
  name                 = "sbnet1"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "nic1" {
  name                = "nic1"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.sbnet1.id
    private_ip_address           = "10.0.1.10"
    private_ip_address_allocation = "Static"
  }
}

resource "tls_private_key" "keypair" {
  algorithm   = "RSA"
  rsa_bits    = 4096
}

module "key_vault" {
  source = "Azure/keyvault/azurerm"

  name       = "kvaultmv1"
  sku_name   = "standard"
  tenant_id  = data.azurerm_client_config.current.tenant_id
  
  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules       = ["188.26.198.118"]
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

  depends_on = [tls_private_key.keypair]
  
  secrets = {
    public-clave = base64encode(tls_private_key.keypair.public_key_openssh)
    secret-clave = base64encode(tls_private_key.keypair.private_key_pem)
  }
}

resource "azurerm_linux_virtual_machine" "vm1" {
  name                = "vm1"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  size                = "Standard_B2s"

  admin_username = "azureuser"

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    name              = "osdisk1"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_ssh_key {
    username   = "azureuser"
    public_key = module.key_vault.secret["public-clave"]
  }

  depends_on = [
    azurerm_network_interface.nic1,
    module.key_vault,
  ]
}

data "azurerm_resource_group" "rg" {
  name = "1-3baf3667-playground-sandbox"
}

data "azurerm_client_config" "current" {}
