output "public_ip" {
  value      = azurerm_public_ip.public_ip.ip_address
  depends_on = [azurerm_public_ip.public_ip]
}

output "public_dns" {
  value      = azurerm_public_ip.public_ip.fqdn
  depends_on = [azurerm_public_ip.public_ip]
}