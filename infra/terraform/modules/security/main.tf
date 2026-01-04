########################################################
# Security groups for nodes, FSx, observability
########################################################

locals {
  name_prefix = "${var.project}-${var.env}"
}

# EKS worker nodes SG
resource "aws_security_group" "nodes" {
  name        = "${local.name_prefix}-nodes-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow node-to-node communication"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-nodes-sg"
  })
}

# FSx security group (allow from nodes)
resource "aws_security_group" "fsx" {
  name        = "${local.name_prefix}-fsx-sg"
  description = "Security group for FSx Lustre"
  vpc_id      = var.vpc_id

  ingress {
    description              = "FSx Lustre access from nodes"
    from_port                = 988
    to_port                  = 988
    protocol                 = "tcp"
    source_security_group_id = aws_security_group.nodes.id
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-fsx-sg"
  })
}
