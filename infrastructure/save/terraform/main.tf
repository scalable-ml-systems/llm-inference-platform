########################################################
# Root module wiring - shared/global
########################################################

locals {
  common_tags = {
    Project = var.project_name
    Env     = var.env
  }
}

module "vpc" {
  source = "./modules/vpc"

  env         = var.env
  project     = var.project_name
  region      = var.region
  common_tags = local.common_tags
}

module "security" {
  source = "./modules/security"

  env         = var.env
  project     = var.project_name
  vpc_id      = module.vpc.vpc_id
  common_tags = local.common_tags
}

module "iam" {
  source = "./modules/iam"

  env         = var.env
  project     = var.project_name
  oidc_provider_arn = var.oidc_provider_arn
  oidc_provider_url = var.oidc_provider_url
  common_tags = local.common_tags
}

module "eks" {
  source = "./modules/eks"

  env              = var.env
  project          = var.project_name
  vpc_id           = module.vpc.vpc_id
  private_subnets  = module.vpc.private_subnets
  node_sg_id       = module.security.node_sg_id
  cluster_role_arn = module.iam.cluster_role_arn
  node_role_arn    = module.iam.node_role_arn
  common_tags      = local.common_tags
}

module "storage" {
  source = "./modules/storage"

  env             = var.env
  project         = var.project_name
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
  common_tags     = local.common_tags
}

module "kms" {
  source = "./modules/kms"

  env         = var.env
  project     = var.project_name
  common_tags = local.common_tags
}

module "ecr" {
  source = "./modules/ecr"

  env         = var.env
  project     = var.project_name
  common_tags = local.common_tags
}

module "cicd" {
  source = "./modules/cicd"

  env          = var.env
  project      = var.project_name
  github_org   = var.github_org
  github_repo  = var.github_repo
  vllm_ecr_arn = module.ecr.vllm_repository_arn
  common_tags  = local.common_tags
}

module "observability" {
  source = "./modules/observability"

  env              = var.env
  project          = var.project_name
  cluster_name     = module.eks.cluster_name
  cluster_endpoint = module.eks.cluster_endpoint
  common_tags      = local.common_tags
}

module "autoscaling" {
  source = "./modules/autoscaling"

  env          = var.env
  project      = var.project_name
  cluster_name = module.eks.cluster_name
  cluster_autoscaler_role_arn = module.iam.cluster_autoscaler_role_arn
  common_tags  = local.common_tags
}

module "cost_management" {
  source = "./modules/cost-management"

  env         = var.env
  project     = var.project_name
  common_tags = local.common_tags
}

module "networking" {
  source = "./modules/networking"

  env         = var.env
  project     = var.project_name
  vpc_id      = module.vpc.vpc_id
  public_subnets  = module.vpc.public_subnets
  private_subnets = module.vpc.private_subnets
  common_tags = local.common_tags
}

module "secrets" {
  source = "./modules/secrets"

  env         = var.env
  project     = var.project_name
  common_tags = local.common_tags
}

module "disaster_recovery" {
  source = "./modules/disaster-recovery"

  env         = var.env
  project     = var.project_name
  vpc_id      = module.vpc.vpc_id
  common_tags = local.common_tags
}

module "testing" {
  source = "./modules/testing"

  env         = var.env
  project     = var.project_name
  cluster_name = module.eks.cluster_name
  vpc_id      = module.vpc.vpc_id
  common_tags = local.common_tags
}
