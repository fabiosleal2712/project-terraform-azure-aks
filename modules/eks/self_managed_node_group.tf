resource "aws_eks_access_entry" "this" {
  count = var.cluster_status != "DELETING" ? 1 : 0

  cluster_name  = var.cluster_name
  principal_arn = var.principal_arn

  depends_on = [aws_eks_cluster.this]
}

resource "aws_eks_access_policy_association" "admin" {
  count = var.cluster_status != "DELETING" ? 1 : 0

  cluster_name  = var.cluster_name
  principal_arn = var.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.this]
}
