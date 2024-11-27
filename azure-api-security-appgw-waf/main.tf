terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

locals  {
  web_ip = ""
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "crapi-appgw-rg"
  location = "West Europe"
}

# Create Network Security Group
resource "azurerm_network_security_group" "nsg" {
  name                = "crapi-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "allow-8888"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8888"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-8025"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8025"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-8443"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8025"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-ssh"
    priority                   = 103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }  
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "crapi-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Frontend
resource "azurerm_subnet" "frontend" {
  name                 = "crapi-frontend-subnet"  
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.0.0/24"]
}

# Frontend
resource "azurerm_subnet" "backend" {
  name                 = "crapi-backend-subnet"  
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Public IP
resource "azurerm_public_ip" "public_ip" {
  name                = "crapi-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}



# Network Interface
resource "azurerm_network_interface" "nic" {
  name                = "crapi-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.backend.id
    private_ip_address_allocation = "Dynamic"
  }
}


resource "azurerm_application_gateway" "app_gateway" {
  name                = "crapi-app-gateway"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "app-gateway-ip-configuration"
    subnet_id = azurerm_subnet.frontend.id
  }

  frontend_port {
    name = "app-gateway-frontend-port-8888"
    port = 8888
  }

  frontend_port {
    name = "app-gateway-frontend-port-8443"
    port = 8443
  }

  frontend_port {
    name = "app-gateway-frontend-port-8025"
    port = 8025
  }

  frontend_ip_configuration {
    name                 = "app-gateway-frontend-ip-configuration"
    public_ip_address_id = azurerm_public_ip.public_ip.id
  }

  backend_address_pool {
    name = "app-gateway-backend-address-pool"
    ip_addresses = [azurerm_network_interface.nic.private_ip_address]
  }

  backend_http_settings {
    name                  = "http-setting-8888"
    cookie_based_affinity = "Disabled"
    port                  = 8888
    protocol              = "Http"
    request_timeout       = 60
  }

  backend_http_settings {
    name                  = "http-setting-8443"
    cookie_based_affinity = "Disabled"
    port                  = 8443
    protocol              = "Http"
    request_timeout       = 60
  }

  backend_http_settings {
    name                  = "http-setting-8025"
    cookie_based_affinity = "Disabled"
    port                  = 8025
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = "app-gateway-listener-8888"
    frontend_ip_configuration_name = "app-gateway-frontend-ip-configuration"
    frontend_port_name             = "app-gateway-frontend-port-8888"
    protocol                       = "Http"
  }

  http_listener {
    name                           = "app-gateway-listener-8443"
    frontend_ip_configuration_name = "app-gateway-frontend-ip-configuration"
    frontend_port_name             = "app-gateway-frontend-port-8443"
    protocol                       = "Http"
  }

  http_listener {
    name                           = "app-gateway-listener-8025"
    frontend_ip_configuration_name = "app-gateway-frontend-ip-configuration"
    frontend_port_name             = "app-gateway-frontend-port-8025"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "app-gateway-routing-rule-8888"
    rule_type                  = "Basic"
    http_listener_name         = "app-gateway-listener-8888"
    backend_address_pool_name  = "app-gateway-backend-address-pool"
    backend_http_settings_name = "http-setting-8888"
    priority                   = 100
  }

  request_routing_rule {
    name                       = "app-gateway-routing-rule-8443"
    rule_type                  = "Basic"
    http_listener_name         = "app-gateway-listener-8443"
    backend_address_pool_name  = "app-gateway-backend-address-pool"
    backend_http_settings_name = "http-setting-8443"
    priority                   = 200
  }

  request_routing_rule {
    name                       = "app-gateway-routing-rule-8025"
    rule_type                  = "Basic"
    http_listener_name         = "app-gateway-listener-8025"
    backend_address_pool_name  = "app-gateway-backend-address-pool"
    backend_http_settings_name = "http-setting-8025"
    priority                   = 300
  }
}
# Associate NSG with Network Interface
resource "azurerm_network_interface_security_group_association" "nic_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}


# Generate a random string for unique resource names
resource "random_string" "suffix" {
  length  = 8
  special = false
}

# Virtual Machine
resource "azurerm_virtual_machine" "vm" {
  name                  = "crapi-vm"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic.id]
  vm_size               = "Standard_DS1_v2"

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
 
}