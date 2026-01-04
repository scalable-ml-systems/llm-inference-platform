########################################################
# Networking: ALB ingress, optional mesh hooks
########################################################

locals {
  name_prefix = "${var.project}-${var.env}"
}

# AWS Load Balancer Controller IAM role is usually IRSA-based;
# here we only create a security group placeholder for ALB/NLB.

resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-sg"
  description = "Security group for ALB ingress"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-alb-sg"
  })
}

# Optional: you can add aws_lb, aws_lb_target_group, etc. later.
# For now, separate components for controller and mesh.

module "alb_controller" {
  source = "./components/alb-controller"
}
# "istio" component is optional; left as structure only.
