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
