# Exemplo de uso do módulo Azure PostgreSQL

Este é um exemplo de referência. Veja o arquivo `database.tf` na raiz do projeto para o uso real.

```terraform
module "postgresql" {
  source = "./modules/azure-postgresql"

  server_name         = "${var.project_name}-${var.environment}-postgres"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  administrator_login    = var.db_admin_username
  administrator_password = var.db_admin_password

  # SKU Options:
  # Burstable: B_Standard_B1ms (1 vCore, 2GB RAM) - Dev/Test
  # General Purpose: GP_Standard_D2s_v3 (2 vCore, 8GB RAM) - Produção
  sku_name   = var.db_sku_name
  storage_mb = var.db_storage_mb
  postgres_version = var.db_postgres_version

  # Backup
  backup_retention_days        = var.db_backup_retention_days
  geo_redundant_backup_enabled = var.db_geo_redundant_backup

  # Alta disponibilidade (opcional - custa mais)
  high_availability_enabled = var.db_high_availability_enabled
  standby_availability_zone = var.db_standby_zone

  # Networking - Opção 1: Public access com firewall
  # delegated_subnet_id = null
  # private_dns_zone_id = null

  # Networking - Opção 2: VNet integration (recomendado para produção)
  # delegated_subnet_id = azurerm_subnet.database.id
  # private_dns_zone_id = azurerm_private_dns_zone.postgres.id
  # vnet_id             = azurerm_virtual_network.main.id
  # create_private_dns_zone = true

  database_name = var.db_database_name

  tags = merge(var.tags, {
    Component = "Database"
  })
}

# Outputs úteis
output "postgres_fqdn" {
  description = "FQDN do servidor PostgreSQL"
  value       = module.postgresql.server_fqdn
}

output "postgres_connection_string" {
  description = "Connection string (sem senha)"
  value       = module.postgresql.connection_string
}

output "postgres_database_name" {
  description = "Nome do database"
  value       = module.postgresql.database_name
}
```
