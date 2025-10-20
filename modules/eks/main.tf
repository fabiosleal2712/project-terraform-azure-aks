# EKS Cluster simplificado
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = var.cluster_role_arn
  version  = "1.30"

  vpc_config {
    subnet_ids              = var.subnet_ids
    security_group_ids      = var.security_group_ids
    endpoint_public_access  = true
    endpoint_private_access = false
  }

  # Necessário para usar aws_eks_access_entry
  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }

  tags = {
    Name        = var.cluster_name
    Environment = "development"
  }
}