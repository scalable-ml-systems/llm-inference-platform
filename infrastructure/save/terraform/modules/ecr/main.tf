########################################################
# ECR repositories for vLLM and router
########################################################

locals {
  name_prefix = "${var.project}-${var.env}"
}

resource "aws_ecr_repository" "vllm" {
  name                 = "${local.name_prefix}/vllm"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-vllm-ecr"
  })
}

resource "aws_ecr_repository" "router" {
  name                 = "${local.name_prefix}/router"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-router-ecr"
  })
}
