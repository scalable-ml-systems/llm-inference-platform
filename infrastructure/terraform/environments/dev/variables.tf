variable "region" {
  type        = string
  description = "AWS region"
}

variable "account_id" {
  description = "AWS account ID for this environment"
  type        = string
}

variable "profile" {
  type        = string
  description = "AWS account profile"
}

variable "project_name" {
  type        = string
  description = "Project name"
  default     = "llm-inference-platform"
}

variable "env" {
  type        = string
  description = "Environment name"
  default     = "dev"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR"
  default     = "10.20.0.0/16"
}

variable "az_count" {
  type        = number
  description = "Number of AZs"
  default     = 2
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
  default     = "llm-inference-platform-dev"
}

variable "kubernetes_version" {
  type        = string
  description = "EKS Kubernetes version"
  default     = "1.29"
}

variable "gpu_instance_type" {
  type        = string
  description = "GPU instance type"
  default     = "g4dn.xlarge"
}

variable "gpu_desired_size" {
  type    = number
  default = 2
}

variable "gpu_min_size" {
  type    = number
  default = 0
}

variable "gpu_max_size" {
  type    = number
  default = 2
}

variable "models_bucket_name" {
  type        = string
  description = "S3 bucket for model artifacts"
}

variable "force_destroy_models_bucket" {
  type        = bool
  description = "Allow terraform destroy to delete bucket contents (dev only)"
  default     = true
}

variable "enable_gpu" {
  type    = bool
  default = false
}
