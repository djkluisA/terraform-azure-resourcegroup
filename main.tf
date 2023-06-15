
resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096

  depends_on = [
    azurerm_key_vault.doskeyvault1406,
    azurerm_linux_virtual_machine.cuatro
  ]

  lifecycle {
    ignore_changes = [
      tls_private_key.key.private_key_pem,
      tls_private_key.key.public_key_openssh
    ]
  }
}
