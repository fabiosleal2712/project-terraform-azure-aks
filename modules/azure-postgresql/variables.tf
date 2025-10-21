variable "server_name" {
  description = "Nome do servidor PostgreSQL"
  type        = string
}

variable "resource_group_name" {
  description = "Nome do resource group"
  type        = string
}

variable "location" {
  description = "Localização do Azure"
  type        = string
}

variable "administrator_login" {
  description = "Login do administrador"
  type        = string
  default     = "psqladmin"
}

variable "administrator_password" {
  description = "Senha do administrador (mínimo 8 caracteres)"
  type        = string
  sensitive   = true
}

variable "sku_name" {
  description = "SKU do servidor (ex: B_Standard_B1ms, GP_Standard_D2s_v3)"
  type        = string
  default     = "B_Standard_B1ms" # Burstable - mais barato para dev
}

variable "storage_mb" {
  description = "Armazenamento em MB (mínimo 32768 = 32GB)"
  type        = number
  default     = 32768
}

variable "postgres_version" {
  description = "Versão do PostgreSQL (11, 12, 13, 14, 15, 16)"
  type        = string
  default     = "16"
}

variable "backup_retention_days" {
  description = "Dias de retenção de backup (7-35)"
  type        = number
  default     = 7
}

variable "geo_redundant_backup_enabled" {
  description = "Habilitar backup geo-redundante"
  type        = bool
  default     = false
}

variable "high_availability_enabled" {
  description = "Habilitar alta disponibilidade (zone redundant)"
  type        = bool
  default     = false
}

variable "standby_availability_zone" {
  description = "Zona de disponibilidade para standby (se HA habilitado)"
  type        = string
  default     = "2"
}

variable "delegated_subnet_id" {
  description = "ID da subnet delegada para PostgreSQL"
  type        = string
  default     = null
}

variable "private_dns_zone_id" {
  description = "ID da private DNS zone"
  type        = string
  default     = null
}

variable "vnet_id" {
  description = "ID da VNet para DNS zone link"
  type        = string
  default     = null
}

variable "create_private_dns_zone" {
  description = "Criar private DNS zone automaticamente"
  type        = bool
  default     = false
}

variable "database_name" {
  description = "Nome do database"
  type        = string
  default     = "nutrivedadb"
}

variable "maintenance_window_day" {
  description = "Dia da semana para manutenção (0-6, 0=domingo)"
  type        = number
  default     = 0
}

variable "maintenance_window_hour" {
  description = "Hora de início da manutenção (0-23)"
  type        = number
  default     = 3
}

variable "maintenance_window_minute" {
  description = "Minuto de início da manutenção (0-59)"
  type        = number
  default     = 0
}

variable "timezone" {
  description = "Timezone do servidor"
  type        = string
  default     = "America/Sao_Paulo"
}

variable "tags" {
  description = "Tags para os recursos"
  type        = map(string)
  default     = {}
}
