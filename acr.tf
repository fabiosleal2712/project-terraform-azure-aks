# Azure Container Registry
resource "azurerm_container_registry" "main" {
  name                = "${replace(var.project_name, "-", "")}${var.environment}acr${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = var.acr_sku
  admin_enabled       = false

  # Geo-replication (apenas Premium)
  dynamic "georeplications" {
    for_each = var.acr_sku == "Premium" ? [1] : []
    content {
      location                = var.location_secondary
      zone_redundancy_enabled = true
      tags = merge(
        var.tags,
        {
          Environment = var.environment
        }
      )
    }
  }

  # Network Rules
  network_rule_set {
    default_action = "Allow"

    virtual_network {
      action    = "Allow"
      subnet_id = azurerm_subnet.aks.id
    }
  }

  # Retention Policy (Premium apenas)
  dynamic "retention_policy" {
    for_each = var.acr_sku == "Premium" ? [1] : []
    content {
      days    = 7
      enabled = true
    }
  }

  # Trust Policy (Premium apenas)
  dynamic "trust_policy" {
    for_each = var.acr_sku == "Premium" ? [1] : []
    content {
      enabled = true
    }
  }

  tags = merge(
    var.tags,
    {
      Environment = var.environment
      Name        = "${var.project_name}-${var.environment}-acr"
    }
  )
}
