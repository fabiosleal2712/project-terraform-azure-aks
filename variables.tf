variable "project_name" {
  description = "Nome do projeto"
  type        = string
  default     = "myaksproject"
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment deve ser dev, staging ou prod."
  }
}

variable "location" {
  description = "Localização dos recursos Azure"
  type        = string
  default     = "brazilsouth"
}

variable "location_secondary" {
  description = "Localização secundária para DR"
  type        = string
  default     = "eastus2"
}

# Network Variables
variable "vnet_address_space" {
  description = "Address space da VNet"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "aks_subnet_address_prefix" {
  description = "Address prefix da subnet do AKS"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "appgw_subnet_address_prefix" {
  description = "Address prefix da subnet do Application Gateway"
  type        = list(string)
  default     = ["10.0.2.0/24"]
}

# AKS Variables
variable "kubernetes_version" {
  description = "Versão do Kubernetes"
  type        = string
  default     = "1.28.3"
}

variable "aks_node_count" {
  description = "Número de nodes no pool padrão"
  type        = number
  default     = 2

  validation {
    condition     = var.aks_node_count >= 1 && var.aks_node_count <= 100
    error_message = "Node count deve estar entre 1 e 100."
  }
}

variable "aks_node_vm_size" {
  description = "Tamanho da VM dos nodes"
  type        = string
  default     = "Standard_D2s_v6"
}

variable "aks_enable_auto_scaling" {
  description = "Habilitar auto scaling"
  type        = bool
  default     = true
}

variable "aks_min_count" {
  description = "Número mínimo de nodes (auto scaling)"
  type        = number
  default     = 1
}

variable "aks_max_count" {
  description = "Número máximo de nodes (auto scaling)"
  type        = number
  default     = 5
}

variable "aks_max_pods" {
  description = "Número máximo de pods por node"
  type        = number
  default     = 30
}

variable "aks_os_disk_size_gb" {
  description = "Tamanho do disco OS em GB"
  type        = number
  default     = 128
}

# ACR Variables
variable "acr_sku" {
  description = "SKU do Azure Container Registry"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.acr_sku)
    error_message = "ACR SKU deve ser Basic, Standard ou Premium."
  }
}

# Monitoring Variables
variable "log_analytics_retention_days" {
  description = "Dias de retenção dos logs"
  type        = number
  default     = 30
}

# Tags
variable "tags" {
  description = "Tags para todos os recursos"
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
    Project   = "AKS Infrastructure"
  }
}

# Network Security
variable "allowed_ip_ranges" {
  description = "Ranges de IP permitidos para acesso ao cluster"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Alterar em produção!
}

# Database Variables
variable "db_admin_username" {
  description = "Username do administrador do PostgreSQL"
  type        = string
  default     = "psqladmin"
}

variable "db_admin_password" {
  description = "Senha do administrador do PostgreSQL (mínimo 8 caracteres)"
  type        = string
  sensitive   = true
  default     = null # Deve ser fornecida via terraform.tfvars ou variável de ambiente
}

variable "db_sku_name" {
  description = "SKU do PostgreSQL (B_Standard_B1ms para dev, GP_Standard_D2s_v3 para prod)"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "db_storage_mb" {
  description = "Armazenamento do PostgreSQL em MB"
  type        = number
  default     = 32768 # 32 GB
}

variable "db_postgres_version" {
  description = "Versão do PostgreSQL"
  type        = string
  default     = "16"
}

variable "db_backup_retention_days" {
  description = "Dias de retenção de backup"
  type        = number
  default     = 7
}

variable "db_geo_redundant_backup" {
  description = "Habilitar backup geo-redundante"
  type        = bool
  default     = false
}

variable "db_high_availability_enabled" {
  description = "Habilitar alta disponibilidade (custa mais)"
  type        = bool
  default     = false
}

variable "db_standby_zone" {
  description = "Zona de disponibilidade para standby"
  type        = string
  default     = "2"
}

variable "db_database_name" {
  description = "Nome do database"
  type        = string
  default     = "nutrivedadb"
}