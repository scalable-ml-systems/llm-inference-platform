########################################################
# Disaster Recovery: snapshots, backup policies (stubs)
########################################################

locals {
  name_prefix = "${var.project}-${var.env}"
}

# Placeholder: this is where you'd define:
# - aws_backup_vault
# - aws_backup_plan
# - Backup selections for EFS/FSx, RDS if you add it later.

resource "aws_backup_vault" "main" {
  name        = "${local.name_prefix}-backup-vault"
  kms_key_arn = null

  tags = var.common_tags
}

resource "aws_backup_plan" "daily" {
  name = "${local.name_prefix}-daily-backup-plan"

  rule {
    rule_name         = "daily-backup"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 5 * * ? *)" # Daily at 05:00 UTC

    lifecycle {
      delete_after = 30
    }
  }

  tags = var.common_tags
}

# You will later add backup selections for FSx or other resources.
