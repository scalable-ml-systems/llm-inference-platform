resource "aws_eks_node_group" "system" {
  cluster_name    = var.cluster_name
  node_group_name = "${var.cluster_name}-system"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids

  instance_types = [var.instance_type]
  capacity_type  = "ON_DEMAND"
  disk_size      = 50

  scaling_config {
    desired_size = var.desired_size
    min_size     = var.min_size
    max_size     = var.max_size
  }

  labels = {
    workload = "system"
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-system-ng"
  })
}
