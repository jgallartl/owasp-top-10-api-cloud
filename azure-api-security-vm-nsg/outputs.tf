output "public_ip" {
  value = azurerm_public_ip.vm_public_ip.ip_address
}

output "public_dns" {
  value = azurerm_public_ip.vm_public_ip.fqdn
}
