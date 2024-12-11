resource "azurerm_api_management" "apim" {
  name                = "crapi-apim"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  publisher_name      = "Your Company"
  publisher_email     = "your-email@example.com"
  sku_name            = "Developer_1"

  virtual_network_configuration {
    subnet_id = azurerm_subnet.backend.id
  }

  virtual_network_type = "Internal"

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = "development"
  }

  depends_on = [ 
        azurerm_network_interface_security_group_association.nic_nsg_assoc
   ]
}

resource "azurerm_api_management_api" "apim_api" {
  name                = "crapi-api"
  resource_group_name = azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.apim.name
  revision            = "1"
  display_name        = "crApi API"
  path                = ""
  protocols           = ["http"]

#  import {
#    content_format = "swagger-link-json"
#    content_value  = "https://raw.githubusercontent.com/OWASP/crAPI/refs/heads/develop/openapi-spec/crapi-openapi-spec.json"
#  }
}

resource "azurerm_api_management_api_operation" "apim_op_get" {
  operation_id        = "get-operation"
  api_name            = azurerm_api_management_api.apim_api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "GET Operation"
  method              = "GET"
  url_template        = "/"
  response {
    status_code      = 200
    description = "Successful operation"
  }
}

resource "azurerm_api_management_api_operation" "apim_op_post" {
  operation_id        = "post-operation"
  api_name            = azurerm_api_management_api.apim_api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "POST Operation"
  method              = "POST"
  url_template        = "/"
  response {
    status_code      = 200
    description = "Successful operation"
  }
}

resource "azurerm_api_management_api_operation" "apim_op_put" {
    operation_id        = "put-operation"
    api_name            = azurerm_api_management_api.apim_api.name
    api_management_name = azurerm_api_management.apim.name
    resource_group_name = azurerm_resource_group.rg.name
    display_name        = "PUT Operation"
    method              = "PUT"
    url_template        = "/"
    response {
        status_code      = 200
        description = "Successful operation"
    }  
}

resource "azurerm_api_management_api_operation" "apim_op_delete" {
    operation_id        = "delete-operation"
    api_name            = azurerm_api_management_api.apim_api.name
    api_management_name = azurerm_api_management.apim.name
    resource_group_name = azurerm_resource_group.rg.name
    display_name        = "DELETE Operation"
    method              = "DELETE"
    url_template        = "/"
    response {
        status_code      = 200
        description = "Successful operation"
    }  
}

resource "azurerm_api_management_api_policy" "apim_api_policy" {
  api_name            = azurerm_api_management_api.apim_api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  xml_content         = <<XML
<policies>
    <inbound>
        <rate-limit calls="10" renewal-period="60" />
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
XML
}