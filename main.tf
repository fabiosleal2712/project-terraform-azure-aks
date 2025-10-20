# Resource Group Principal
resource "azurerm_resource_group" "main" {
  name     = "${var.project_name}-${var.environment}-rg"
  location = var.location

  tags = merge(
    var.tags,
    {
      Environment = var.environment
      Name        = "${var.project_name}-${var.environment}-rg"
    }
  )
}

# Random string para recursos únicos
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}