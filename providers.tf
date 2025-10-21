terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Descomente para usar Azure Storage Backend
  # backend "azurerm" {
  #   resource_group_name  = "terraform-state-rg"
  #   storage_account_name = "tfstateaks"
  #   container_name       = "tfstate"
  #   key                  = "aks.terraform.tfstate"
  # }
}

provider "azurerm" {
  subscription_id            = "2febf03a-7aa7-433d-938e-6351f2b27d1c"
  skip_provider_registration = true # Evita tentar registrar providers não disponíveis

  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }

    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

provider "azuread" {}
