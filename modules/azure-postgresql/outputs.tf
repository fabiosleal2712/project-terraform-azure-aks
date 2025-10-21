output "server_id" {
  description = "ID do servidor PostgreSQL"
  value       = azurerm_postgresql_flexible_server.default.id
}

output "server_fqdn" {
  description = "FQDN do servidor PostgreSQL"
  value       = azurerm_postgresql_flexible_server.default.fqdn
}

output "server_name" {
  description = "Nome do servidor PostgreSQL"
  value       = azurerm_postgresql_flexible_server.default.name
}

output "database_name" {
  description = "Nome do database"
  value       = azurerm_postgresql_flexible_server_database.default.name
}

output "administrator_login" {
  description = "Login do administrador"
  value       = azurerm_postgresql_flexible_server.default.administrator_login
}

output "connection_string" {
  description = "Connection string para .NET (sem senha)"
  value       = "Host=${azurerm_postgresql_flexible_server.default.fqdn};Database=${azurerm_postgresql_flexible_server_database.default.name};Username=${azurerm_postgresql_flexible_server.default.administrator_login};SSL Mode=Require"
  sensitive   = false
}

output "connection_string_full" {
  description = "Connection string completa (com senha) - só disponível quando a senha for fornecida"
  value       = var.administrator_password != null ? "Host=${azurerm_postgresql_flexible_server.default.fqdn};Database=${azurerm_postgresql_flexible_server_database.default.name};Username=${azurerm_postgresql_flexible_server.default.administrator_login};Password=${var.administrator_password};SSL Mode=Require" : null
  sensitive   = true
}

output "private_dns_zone_id" {
  description = "ID da private DNS zone (se criada)"
  value       = var.create_private_dns_zone ? azurerm_private_dns_zone.postgres[0].id : null
}
