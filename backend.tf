terraform {
  backend "azurerm" {
    resource_group_name  = var.sa_rg
    storage_account_name = var.sa_name
    container_name       = "terraform"
    key                  = "terraform.tfstate"
  }
}