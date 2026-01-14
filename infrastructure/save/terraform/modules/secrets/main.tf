########################################################
# Secrets: Secrets Manager + SSM Parameter Store
########################################################

locals {
  name_prefix = "${var.project}-${var.env}"
}

# Example: generic secret prefix; real secrets are created per-need.
resource "aws_ssm_parameter" "example_config" {
  name  = "/${local.name_prefix}/example-config"
  type  = "String"
  value = "placeholder"

  tags = var.common_tags
}

resource "aws_secretsmanager_secret" "example_secret" {
  name = "${local.name_prefix}/example-secret"

  tags = var.common_tags
}

resource "aws_secretsmanager_secret_version" "example_secret_version" {
  secret_id     = aws_secretsmanager_secret.example_secret.id
  secret_string = jsonencode({ api_key = "dummy" })
}
