variable "env" {
  type = string
}

variable "project" {
  type = string
}

variable "common_tags" {
  type = map(string)
}

variable "oidc_provider_arn" {
  type        = string
  description = "ARN of the OIDC provider for EKS"
}

variable "oidc_provider_url" {
  type        = string
  description = "Issuer host of the OIDC provider (no https://)"
}

# Service account identities (can override per env)
variable "vllm_namespace" {
  type    = string
  default = "vllm"
}

variable "vllm_service_account" {
  type    = string
  default = "vllm-sa"
}

variable "fsx_csi_namespace" {
  type    = string
  default = "kube-system"
}

variable "fsx_csi_service_account" {
  type    = string
  default = "fsx-csi-controller-sa"
}

variable "prometheus_namespace" {
  type    = string
  default = "monitoring"
}

variable "prometheus_service_account" {
  type    = string
  default = "prometheus-k8s"
}

variable "cluster_autoscaler_namespace" {
  type    = string
  default = "kube-system"
}

variable "cluster_autoscaler_service_account" {
  type    = string
  default = "cluster-autoscaler"
}
