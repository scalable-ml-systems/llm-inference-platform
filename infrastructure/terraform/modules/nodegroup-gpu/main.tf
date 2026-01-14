resource "aws_eks_node_group" "gpu" {
  cluster_name    = var.cluster_name
  node_group_name = "${var.cluster_name}-gpu"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids

  # GPU nodes
  instance_types = [var.instance_type]
  capacity_type  = "ON_DEMAND"

  # IMPORTANT: EKS AL2023 NVIDIA optimized AMI
  ami_type = "AL2023_x86_64_NVIDIA"

  # Root disk (simple path when not using a launch template)
  disk_size = 100

  scaling_config {
    desired_size = var.desired_size
    min_size     = var.min_size
    max_size     = var.max_size
  }

  labels = {
    workload    = "gpu"
    accelerator = "nvidia"
  }

  taint {
    key    = "nvidia.com/gpu"
    value  = "present"
    effect = "NO_SCHEDULE"
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-gpu-ng"
  })
}
