########################################################
# AWS provider configuration
########################################################

provider "aws" {
  region  = var.region
  profile = var.profile
}
