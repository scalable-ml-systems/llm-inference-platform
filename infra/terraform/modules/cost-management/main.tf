########################################################
# Cost Management: CUR bucket & tagging baseline
########################################################

locals {
  name_prefix = "${var.project}-${var.env}"
}

# Optional: dedicated bucket for CUR (cost & usage report)
resource "aws_s3_bucket" "cur" {
  bucket = "${local.name_prefix}-cur"

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-cur"
  })
}

resource "aws_s3_bucket_public_access_block" "cur" {
  bucket = aws_s3_bucket.cur.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Placeholder: later you can add aws_cur_report_definition, Athena, dashboards, etc.
