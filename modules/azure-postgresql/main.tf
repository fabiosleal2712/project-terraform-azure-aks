# Azure PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "default" {
  name                = var.server_name
  resource_group_name = var.resource_group_name
  location            = var.location

  administrator_login    = var.administrator_login
  administrator_password = var.administrator_password

  sku_name   = var.sku_name
  storage_mb = var.storage_mb
  version    = var.postgres_version

  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = var.geo_redundant_backup_enabled

  # Network configuration
  delegated_subnet_id = var.delegated_subnet_id
  private_dns_zone_id = var.private_dns_zone_id

  # High availability (opcional - custa mais)
  dynamic "high_availability" {
    for_each = var.high_availability_enabled ? [1] : []
    content {
      mode                      = "ZoneRedundant"
      standby_availability_zone = var.standby_availability_zone
    }
  }

  # Maintenance window
  maintenance_window {
    day_of_week  = var.maintenance_window_day
    start_hour   = var.maintenance_window_hour
    start_minute = var.maintenance_window_minute
  }

  tags = var.tags
}

# Database
resource "azurerm_postgresql_flexible_server_database" "default" {
  name      = var.database_name
  server_id = azurerm_postgresql_flexible_server.default.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

# Firewall rules para permitir acesso do AKS
resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_postgresql_flexible_server.default.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Configurações adicionais do servidor
resource "azurerm_postgresql_flexible_server_configuration" "extensions" {
  name      = "azure.extensions"
  server_id = azurerm_postgresql_flexible_server.default.id
  value     = "UUID-OSSP,PGCRYPTO"
}

resource "azurerm_postgresql_flexible_server_configuration" "timezone" {
  name      = "timezone"
  server_id = azurerm_postgresql_flexible_server.default.id
  value     = var.timezone
}

# Private DNS Zone (se usar VNet integration)
resource "azurerm_private_dns_zone" "postgres" {
  count               = var.create_private_dns_zone ? 1 : 0
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = var.resource_group_name

  tags = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  count                 = var.create_private_dns_zone ? 1 : 0
  name                  = "${var.server_name}-vnet-link"
  private_dns_zone_name = azurerm_private_dns_zone.postgres[0].name
  resource_group_name   = var.resource_group_name
  virtual_network_id    = var.vnet_id

  tags = var.tags
}
