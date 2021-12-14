# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.31.1"
    }
  }
}

# Configure the Microsoft Azure Provider
# Even if you don't need any feature here, you will have to add an empty block, if you don't terraform will throw an error
provider "azurerm" {
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = "like-and-subscribe"
  location = "eastus"
  tags = {
    environment = "dev"
    source      = "Terraform"
    owner       = "Foo Bar Bag"
  }
}

terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "blitzNetwork"
    workspaces {
      name = "monthly-budget"
    }
  }
}