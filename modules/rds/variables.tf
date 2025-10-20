variable "db_password" {
  description = "Senha do banco de dados"
  type        = string
}

variable "availability_zones" {
  description = "Lista de zonas de disponibilidade"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "subnet_ids" {
  description = "IDs das subnets"
  type        = list(string)
}

variable "security_group_id" {
  description = "ID do grupo de segurança para o RDS"
  type        = string
}

variable "vpc_id" {
  description = "ID da VPC"
  type        = string
}
