
provider "azurerm" {
  skip_provider_registration = true

  features {}
}

data "azurerm_resource_group" "rg" {
  name = "resource group1-2732064a-playground-sandbox"
}

data "azurerm_client_config" "current" {}

resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096

  depends_on = [
    azurerm_key_vault.doskeyvault1406
  ]
}

resource "azurerm_key_vault" "doskeyvault1406" {
  name                = "doskeyvault1406"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  sku_name = "standard"

  tenant_id = data.azurerm_client_config.current.tenant_id
}

output "address_space" {
}

output "address_prefixes" {
}

output "address_prefixes2" {
}

output "private_ip_address" {
}
