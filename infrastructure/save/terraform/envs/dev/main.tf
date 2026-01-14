########################################################
# DEV environment wiring
########################################################

terraform {
  required_version = ">= 1.6.0"
}

locals {
  env = var.env
}

module "root" {
  source = "../../"

  region            = var.region
  profile           = var.profile
  env               = var.env
  project_name      = var.project_name
  github_org        = var.github_org
  github_repo       = var.github_repo
  oidc_provider_arn = var.oidc_provider_arn
  oidc_provider_url = var.oidc_provider_url
}
