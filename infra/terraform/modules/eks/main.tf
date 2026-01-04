########################################################
# EKS cluster + GPU node group
########################################################

locals {
  name_prefix = "${var.project}-${var.env}"
}

resource "aws_eks_cluster" "this" {
  name     = "${local.name_prefix}-eks"
  role_arn = var.cluster_role_arn
  version  = "1.30"

  vpc_config {
    subnet_ids              = var.private_subnets
    endpoint_private_access = true
    endpoint_public_access  = true
    security_group_ids      = [var.node_sg_id]
  }

  tags = var.common_tags
}

resource "aws_eks_node_group" "gpu_nodes" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "gpu-nodes"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.private_subnets

  scaling_config {
    desired_size = 1
    max_size     = 3
    min_size     = 1
  }

  instance_types = ["p4d.24xlarge"]

  tags = var.common_tags
}
