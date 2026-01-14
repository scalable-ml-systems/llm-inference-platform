########################################################
# Core IAM: EKS cluster & node roles
########################################################

locals {
  name_prefix = "${var.project}-${var.env}"
}

# --- EKS cluster role ---
resource "aws_iam_role" "cluster" {
  name = "${local.name_prefix}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# --- EKS node role ---
resource "aws_iam_role" "nodes" {
  name = "${local.name_prefix}-eks-node-role"

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

resource "aws_iam_role_policy_attachment" "node_worker" {
  role       = aws_iam_role.nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_cni" {
  role       = aws_iam_role.nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_ecr" {
  role       = aws_iam_role.nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

########################################################
# IRSA roles: vLLM, FSx CSI, Prometheus, Autoscaler
########################################################

# Helper for OIDC condition key
locals {
  oidc_sub_key = "${var.oidc_provider_url}:sub"
}

# --- vLLM IRSA (S3 models + FSx describe) ---
resource "aws_iam_role" "vllm_irsa" {
  name = "${local.name_prefix}-vllm-irsa"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = var.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          (local.oidc_sub_key) = "system:serviceaccount:${var.vllm_namespace}:${var.vllm_service_account}"
        }
      }
    }]
  })

  tags = var.common_tags
}

resource "aws_iam_policy" "vllm_s3_read" {
  name   = "${local.name_prefix}-vllm-s3-read"
  policy = file("${path.module}/policies/s3_read.json")
}

resource "aws_iam_policy" "vllm_fsx_access" {
  name   = "${local.name_prefix}-vllm-fsx-access"
  policy = file("${path.module}/policies/fsx_access.json")
}

resource "aws_iam_role_policy_attachment" "vllm_attach_s3" {
  role       = aws_iam_role.vllm_irsa.name
  policy_arn = aws_iam_policy.vllm_s3_read.arn
}

resource "aws_iam_role_policy_attachment" "vllm_attach_fsx" {
  role       = aws_iam_role.vllm_irsa.name
  policy_arn = aws_iam_policy.vllm_fsx_access.arn
}

# --- FSx CSI driver IRSA ---
resource "aws_iam_role" "fsx_csi_irsa" {
  name = "${local.name_prefix}-fsx-csi-irsa"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = var.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          (local.oidc_sub_key) = "system:serviceaccount:${var.fsx_csi_namespace}:${var.fsx_csi_service_account}"
        }
      }
    }]
  })

  tags = var.common_tags
}

resource "aws_iam_policy" "fsx_csi_access" {
  name   = "${local.name_prefix}-fsx-csi-access"
  policy = file("${path.module}/policies/fsx_access.json")
}

resource "aws_iam_role_policy_attachment" "fsx_csi_attach" {
  role       = aws_iam_role.fsx_csi_irsa.name
  policy_arn = aws_iam_policy.fsx_csi_access.arn
}

# --- Prometheus IRSA (CloudWatch / optional S3) ---
resource "aws_iam_role" "prometheus_irsa" {
  name = "${local.name_prefix}-prometheus-irsa"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = var.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          (local.oidc_sub_key) = "system:serviceaccount:${var.prometheus_namespace}:${var.prometheus_service_account}"
        }
      }
    }]
  })

  tags = var.common_tags
}

resource "aws_iam_policy" "prometheus_cw_read" {
  name   = "${local.name_prefix}-prometheus-cw-read"
  policy = file("${path.module}/policies/cloudwatch_read.json")
}

resource "aws_iam_role_policy_attachment" "prometheus_attach_cw" {
  role       = aws_iam_role.prometheus_irsa.name
  policy_arn = aws_iam_policy.prometheus_cw_read.arn
}

# --- Cluster Autoscaler IRSA ---
resource "aws_iam_role" "cluster_autoscaler_irsa" {
  name = "${local.name_prefix}-cluster-autoscaler-irsa"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = var.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          (local.oidc_sub_key) = "system:serviceaccount:${var.cluster_autoscaler_namespace}:${var.cluster_autoscaler_service_account}"
        }
      }
    }]
  })

  tags = var.common_tags
}

resource "aws_iam_policy" "cluster_autoscaler" {
  name   = "${local.name_prefix}-cluster-autoscaler"
  policy = file("${path.module}/policies/autoscaler.json")
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler_attach" {
  role       = aws_iam_role.cluster_autoscaler_irsa.name
  policy_arn = aws_iam_policy.cluster_autoscaler.arn
}
