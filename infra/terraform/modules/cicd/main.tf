########################################################
# CI/CD: GitHub OIDC + IAM role + artifact bucket
########################################################

locals {
  name_prefix = "${var.project}-${var.env}"
}

resource "aws_s3_bucket" "artifacts" {
  bucket = "${local.name_prefix}-cicd-artifacts"

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-cicd-artifacts"
  })
}

resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}

# GitHub OIDC provider
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]

  tags = var.common_tags
}

# CI/CD IAM role with OIDC trust
resource "aws_iam_role" "cicd" {
  name = "${local.name_prefix}-cicd-role"

  assume_role_policy = templatefile("${path.module}/policies/github_oidc.json", {
    account_id = data.aws_caller_identity.current.account_id
    org        = var.github_org
    repo       = var.github_repo
  })

  tags = var.common_tags
}

data "aws_caller_identity" "current" {}

# ECR push policy
resource "aws_iam_policy" "ecr_push" {
  name   = "${local.name_prefix}-cicd-ecr-push"
  policy = file("${path.module}/policies/ecr_push.json")
}

resource "aws_iam_role_policy_attachment" "cicd_ecr" {
  role       = aws_iam_role.cicd.name
  policy_arn = aws_iam_policy.ecr_push.arn
}

# S3 artifacts policy
resource "aws_iam_policy" "s3_artifacts" {
  name   = "${local.name_prefix}-cicd-s3-artifacts"
  policy = templatefile("${path.module}/policies/s3_artifacts.json", {
    bucket_arn = aws_s3_bucket.artifacts.arn
  })
}

resource "aws_iam_role_policy_attachment" "cicd_s3" {
  role       = aws_iam_role.cicd.name
  policy_arn = aws_iam_policy.s3_artifacts.arn
}
