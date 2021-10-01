terraform {
  backend "azurerm" {
    resource_group_name  = "pma"
    storage_account_name = "allantaylorpma"
    container_name       = "terraform"
    key                  = "spoke-workspace.tfstate"
  }
}
