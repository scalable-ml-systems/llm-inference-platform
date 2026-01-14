########################################################
# KMS keys for S3, FSx, logs, ECR
########################################################

locals {
  name_prefix = "${var.project}-${var.env}"
}

resource "aws_kms_key" "general" {
  description             = "General KMS key for ${local.name_prefix}"
  enable_key_rotation     = true
  deletion_window_in_days = 7

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-kms"
  })
}
