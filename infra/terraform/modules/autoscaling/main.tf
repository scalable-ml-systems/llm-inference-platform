########################################################
# Autoscaling: Cluster Autoscaler IRSA & policy stub
########################################################

locals {
  name_prefix = "${var.project}-${var.env}"
}

# OIDC provider is typically created in EKS/IAM modules.
# Here we assume it's already set up and passed in later if needed.
# For now, we create just an IAM role & policy stub.

resource "aws_iam_role" "cluster_autoscaler" {
  name = "${local.name_prefix}-cluster-autoscaler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = var.common_tags
}

# Minimal autoscaler policy – replace with real autoscaling.json later
resource "aws_iam_policy" "cluster_autoscaler_policy" {
  name   = "${local.name_prefix}-cluster-autoscaler-policy"
  policy = file("${path.module}/policies/gpu-scaling.json")
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler_attach" {
  role       = aws_iam_role.cluster_autoscaler.name
  policy_arn = aws_iam_policy.cluster_autoscaler_policy.arn
}

# Placeholder for queue-based-scaling later (router-aware)
