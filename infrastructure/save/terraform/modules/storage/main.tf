########################################################
# S3 model bucket + FSx Lustre
########################################################

locals {
  name_prefix = "${var.project}-${var.env}"
}

resource "aws_s3_bucket" "models" {
  bucket = "${local.name_prefix}-models"

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-models"
  })
}

resource "aws_s3_bucket_public_access_block" "models" {
  bucket = aws_s3_bucket.models.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# FSx Lustre (can be optionally disabled in dev)
resource "aws_fsx_lustre_file_system" "fsx" {
  subnet_ids       = [var.private_subnets[0]]
  deployment_type  = "PERSISTENT_1"
  storage_capacity = 1200

  security_group_ids = [] # will be wired in later if needed at module level

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-fsx"
  })
}
