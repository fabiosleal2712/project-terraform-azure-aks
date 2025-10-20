variable "vpc_id" {
  description = "ID da VPC"
  type        = string
}

variable "subnet_ids" {
  description = "IDs das subnets"
  type        = list(string)
}

variable "security_group_id" {
  description = "ID do Security Group"
  type        = string
}

variable "ami_id" {
  description = "ID da AMI"
  type        = string
}

variable "instance_type" {
  description = "Tipo de instância"
  type        = string
}