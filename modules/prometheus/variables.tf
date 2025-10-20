variable "vpc_id" {
  description = "ID da VPC onde o Grafana será implantado"
  type        = string
}

variable "subnet_ids" {
  description = "IDs das subnets onde o Grafana será implantado"
  type        = list(string)
}