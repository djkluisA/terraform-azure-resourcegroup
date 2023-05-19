
provider "azurerm" {
  skip_provider_registration = true

  features {}

}

data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "rg" {
  name = "1-3baf3667-playground-sandbox"
}

resource "azurerm_virtual_network" "vnet1" {
  name                = "vnet1"
  resource_group_name = data.azurerm_resource_group.rg.name
  address_space       = var.address_space
}

resource "azurerm_subnet" "sbnet1" {
  name                 = "sbnet1"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = var.address_prefixes
}

resource "azurerm_network_interface" "nic1" {
  name                = "nic1"
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.sbnet1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.private_ip_address
  }
}

resource "tls_private_key" "key_pair" {
  algorithm   = "RSA"
  rsa_bits    = 4096

  depends_on = [
    azurerm_key_vault.kvaultmv1
  ]

  lifecycle {
    ignore_changes = [
      "private_key_pem",
      "public_key_openssh",
    ]
  }

  provisioner "local-exec" {
    command = "az keyvault secret set --vault-name kvaultmv1 --name 'secret-clave' --value ${self.private_key_pem}"

    environment_variables = {
      AZURE_TENANT_ID = data.azurerm_client_config.current.tenant_id
    }
  }

  provisioner "local-exec" {
    command = "az keyvault secret set --vault-name kvaultmv1 --name 'public-clave' --value ${self.public_key_openssh}"

    environment_variables = {
      AZURE_TENANT_ID = data.azurerm_client_config.current.tenant_id
    }
  }
}

resource "azurerm_key_vault" "kvaultmv1" {
  name                = "kvaultmv1"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  network_acls {
    bypass                 = "AzureServices"
    default_action         = "Deny"
    ip_rules               = ["188.26.198.118"]
    virtual_network_subnet = []
  }

  access_policy {
    tenant_id     = data.azurerm_client_config.current.tenant_id
    object_id     = data.azurerm_client_config.current.object_id
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

resource "azurerm_linux_virtual_machine" "vm1" {
  name              = "vm1"
  resource_group_name = data.azurerm_resource_group.rg.name
  location          = data.azurerm_resource_group.rg.location
  size              = "Standard_B2s"

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    name                 = "osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_username = "azureuser"

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.key_pair.public_key_openssh

    depends_on = [
      tls_private_key.key_pair
    ]
  }
}

variable "address_space" {}

variable "address_prefixes" {}

variable "private_ip_address" {}
