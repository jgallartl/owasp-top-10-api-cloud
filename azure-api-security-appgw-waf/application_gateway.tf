resource "azurerm_application_gateway" "app_gateway" {
  name                = "crapi-app-gateway"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
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
    name         = "app-gateway-backend-address-pool"
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

  waf_configuration {
    enabled          = true
    firewall_mode    = "Prevention"
    rule_set_type    = "OWASP"
    rule_set_version = "3.2"
  }
}

resource "azurerm_monitor_diagnostic_setting" "appgw_diagnostic_setting" {
  name                       = "crapi-appgw-diagnostic-setting"
  target_resource_id         = azurerm_application_gateway.app_gateway.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.crapi_law.id

  enabled_log {
    category = "ApplicationGatewayAccessLog"
  }

  enabled_log {
    category = "ApplicationGatewayPerformanceLog"
  }

  enabled_log {
    category = "ApplicationGatewayFirewallLog"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }

}


resource "azurerm_log_analytics_workspace" "crapi_law" {
  name                = "crapi-law"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

