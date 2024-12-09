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

locals {
  web_ip = ""
}

resource "azurerm_resource_group" "rg" {
  name     = "crapi-appgw-rg"
  location = "West Europe"
}
