variable "vpc_id" {
  description = "ID da VPC"
  type        = string
}

variable "subnet_ids" {
  description = "IDs das subnets"
  type        = list(string)
}

variable "security_group_id" {
  description = "ID do grupo de segurança para as instâncias EC2"
  type        = string
  default     = "sg-000031672e37c8557"
}

variable "cluster_name" {
  description = "Nome do cluster EKS"
  type        = string
}

variable "cluster_role_arn" {
  description = "ARN da role do cluster EKS"
  type        = string
}

variable "cluster_status" {
  description = "Status do cluster EKS"
  type        = string
}

variable "security_group_ids" {
  description = "IDs dos grupos de segurança"
  type        = list(string)
}

variable "principal_arn" {
  description = "ARN do principal"
  type        = string
}

variable "node_role_arn" {
  description = "ARN da IAM Role para as instâncias do Managed Node Group"
  type        = string
}

variable "node_group_name" {
  description = "Nome do Managed Node Group"
  type        = string
  default     = "default-ng"
}

variable "node_instance_types" {
  description = "Tipos de instância para os nós"
  type        = list(string)
  default     = ["t3.micro"]
}

variable "node_desired_size" {
  description = "Número desejado de nós"
  type        = number
  default     = 1
}

variable "node_min_size" {
  description = "Número mínimo de nós"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Número máximo de nós"
  type        = number
  default     = 1
}

variable "node_disk_size" {
  description = "Tamanho do disco para os nós (GiB)"
  type        = number
  default     = 20
}