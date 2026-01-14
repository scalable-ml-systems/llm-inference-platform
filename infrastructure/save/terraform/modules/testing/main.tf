########################################################
# Infra testing: smoke tests / validation stubs
########################################################

locals {
  name_prefix = "${var.project}-${var.env}"
}

# This module is intended for validation resources, not production infra.
# For now, it's a placeholder that wires into test files under ./tests.

resource "null_resource" "infra_tests" {
  triggers = {
    cluster_name = var.cluster_name
    vpc_id       = var.vpc_id
  }
}
