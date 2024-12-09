resource "random_string" "suffix" {
  length  = 8
  special = false
}


resource "azurerm_virtual_machine" "vm" {
  name                  = "crapi-vm"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic.id]
  vm_size               = "Standard_DS1_v2"
  delete_os_disk_on_termination = true

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/azureuser/.ssh/authorized_keys"
      key_data = file("~/.ssh/id_rsa_crapi.pub")
    }
  }

  storage_os_disk {
    name              = "osdisk-${random_string.suffix.result}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  os_profile {
    computer_name  = "crapi-vm"
    admin_username = "azureuser"
    custom_data = filebase64("../resources/cloud-init.txt")
  }

  depends_on = [azurerm_public_ip.vm_public_ip]
}
