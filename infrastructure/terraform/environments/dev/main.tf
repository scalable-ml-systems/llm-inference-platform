locals {
  inference_namespace      = "inference-backend"
  inference_serviceaccount = "inference-backend-sa"

  # IAM trust policy needs the OIDC issuer host/path without the "https://"
  oidc_provider_hostpath = replace(module.cluster_eks.oidc_issuer_url, "https://", "")
}

module "network_vpc" {
  source   = "../../modules/network-vpc"
  name     = "${var.project_name}-${var.env}"
  cidr     = var.vpc_cidr
  az_count = var.az_count

  tags = {
    project = var.project_name
    env     = var.env
  }
}

module "iam_roles" {
  source = "../../modules/iam-roles"
  name   = "${var.project_name}-${var.env}"

  tags = {
    project = var.project_name
    env     = var.env
  }
}

module "cluster_eks" {
  source             = "../../modules/cluster-eks"
  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version
  vpc_id             = module.network_vpc.vpc_id
  private_subnet_ids  = module.network_vpc.private_subnet_ids
  eks_cluster_role_arn = module.iam_roles.eks_cluster_role_arn

  tags = {
    project = var.project_name
    env     = var.env
  }
}

module "nodegroup_gpu" {
  source        = "../../modules/nodegroup-gpu"
  cluster_name  = module.cluster_eks.cluster_name
  subnet_ids    = module.network_vpc.private_subnet_ids
  node_role_arn = module.iam_roles.node_role_arn

  instance_type = var.gpu_instance_type
  desired_size  = var.gpu_desired_size
  min_size      = var.gpu_min_size
  max_size      = var.gpu_max_size

  depends_on = [module.cluster_eks]

  tags = {
    project = var.project_name
    env     = var.env
  }
}

# IAM policy: S3 read-only to the models bucket
# ==============================================

resource "aws_s3_bucket" "models" {
  bucket        = var.models_bucket_name
  force_destroy = var.force_destroy_models_bucket
}

resource "aws_s3_bucket_versioning" "models" {
  bucket = aws_s3_bucket.models.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "models" {
  bucket = aws_s3_bucket.models.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "models" {
  bucket                  = aws_s3_bucket.models.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "models_s3_readonly" {
  statement {
    sid     = "ListBucket"
    actions = ["s3:ListBucket", "s3:GetBucketLocation"]
    resources = [
      aws_s3_bucket.models.arn
    ]
  }

  statement {
    sid     = "ReadObjects"
    actions = ["s3:GetObject"]
    resources = [
      "${aws_s3_bucket.models.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "models_s3_readonly" {
  name   = "${var.project_name}-${var.env}-models-s3-readonly"
  policy = data.aws_iam_policy_document.models_s3_readonly.json
}

# IAM role: Kubernetes Service Account (IRSA)
# =============================================
data "aws_iam_policy_document" "irsa_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [module.cluster_eks.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_hostpath}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_hostpath}:sub"
      values   = ["system:serviceaccount:${local.inference_namespace}:${local.inference_serviceaccount}"]
    }
  }
}

resource "aws_iam_role" "inference_backend_irsa" {
  name               = "${var.project_name}-${var.env}-inference-backend-irsa"
  assume_role_policy = data.aws_iam_policy_document.irsa_assume_role.json
}

resource "aws_iam_role_policy_attachment" "inference_backend_models_access" {
  role       = aws_iam_role.inference_backend_irsa.name
  policy_arn  = aws_iam_policy.models_s3_readonly.arn
}
