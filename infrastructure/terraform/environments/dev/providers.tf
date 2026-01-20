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

data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = var.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}
