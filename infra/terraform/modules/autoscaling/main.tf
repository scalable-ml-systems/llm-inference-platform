########################################################
# Autoscaling: placeholder using IRSA role
########################################################

locals {
  name_prefix = "${var.project}-${var.env}"
}

# Later, you will add a helm_release here for cluster-autoscaler
# using the var.cluster_autoscaler_role_arn in the serviceAccount
# annotation: eks.amazonaws.com/role-arn

resource "null_resource" "autoscaling_stub" {
  triggers = {
    cluster_name              = var.cluster_name
    cluster_autoscaler_role   = var.cluster_autoscaler_role_arn
  }
}
