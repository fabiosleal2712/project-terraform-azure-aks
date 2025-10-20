resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = var.node_group_name
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  disk_size      = var.node_disk_size
  instance_types = var.node_instance_types

  update_config {
    max_unavailable = 1
  }

  tags = {
    Name = var.node_group_name
  }

  depends_on = [aws_eks_cluster.this]
}
