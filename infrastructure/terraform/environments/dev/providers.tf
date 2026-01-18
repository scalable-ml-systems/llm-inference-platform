provider "aws" {
  region  = var.region
  profile = var.profile

  default_tags {
    tags = {
      project = var.project_name
      env     = var.env
      owner   = "llm-inference-platform"
    }
  }
}
