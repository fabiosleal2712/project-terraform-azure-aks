# Azure PostgreSQL Flexible Server
# Descomentar este bloco para provisionar o banco de dados

# Subnet dedicada para o PostgreSQL (VNet integration)
resource "azurerm_subnet" "database" {
  name                 = "${var.project_name}-${var.environment}-db-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.3.0/24"]

  delegation {
    name = "postgresql-delegation"

    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

# Private DNS Zone para PostgreSQL
resource "azurerm_private_dns_zone" "postgres" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.main.name

  tags = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  name                  = "${var.project_name}-${var.environment}-postgres-vnet-link"
  private_dns_zone_name = azurerm_private_dns_zone.postgres.name
  resource_group_name   = azurerm_resource_group.main.name
  virtual_network_id    = azurerm_virtual_network.main.id

  tags = var.tags
}

# PostgreSQL Flexible Server
module "postgresql" {
  source = "./modules/azure-postgresql"

  server_name         = "${var.project_name}-${var.environment}-postgres"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  administrator_login    = var.db_admin_username
  administrator_password = var.db_admin_password

  sku_name         = var.db_sku_name
  storage_mb       = var.db_storage_mb
  postgres_version = var.db_postgres_version

  backup_retention_days        = var.db_backup_retention_days
  geo_redundant_backup_enabled = var.db_geo_redundant_backup

  high_availability_enabled = var.db_high_availability_enabled
  standby_availability_zone = var.db_standby_zone

  # VNet Integration
  delegated_subnet_id = azurerm_subnet.database.id
  private_dns_zone_id = azurerm_private_dns_zone.postgres.id
  vnet_id             = azurerm_virtual_network.main.id

  database_name = var.db_database_name

  tags = merge(var.tags, {
    Component = "Database"
  })

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.postgres
  ]
}
