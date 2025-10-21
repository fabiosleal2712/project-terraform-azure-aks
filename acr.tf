# Azure Container Registry
resource "azurerm_container_registry" "main" {
  name                = "${replace(var.project_name, "-", "")}${var.environment}acr${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = var.acr_sku
  admin_enabled       = false

  # Geo-replication (apenas Premium) - Usar recurso separado em azurerm 4.x
  # Para implementar geo-replication, use: azurerm_container_registry_georeplica

  tags = merge(
    var.tags,
    {
      Environment = var.environment
      Name        = "${var.project_name}-${var.environment}-acr"
    }
  )
}
