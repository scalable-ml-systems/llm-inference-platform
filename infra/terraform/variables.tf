########################################################
# Global variables
########################################################

variable "region" {
  type        = string
  description = "AWS region for deployment"
  default     = "us-east-1"
}

variable "profile" {
  type        = string
  description = "AWS CLI profile"
  default     = null
}

variable "env" {
  type        = string
  description = "Environment name (dev|staging|prod)"
}

variable "project_name" {
  type        = string
  description = "Project name prefix for tagging and naming"
  default     = "vllm-platform"
}

variable "github_org" {
  type        = string
  description = "GitHub organization for CI/CD OIDC binding"
  default     = "your-org"
}

variable "github_repo" {
  type        = string
  description = "GitHub repository for CI/CD OIDC binding (org/repo)"
  default     = "your-org/your-repo"
}
