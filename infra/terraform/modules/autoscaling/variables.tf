variable "env" {
  type = string
}

variable "project" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "cluster_autoscaler_role_arn" {
  type        = string
  description = "IRSA role ARN for Cluster Autoscaler"
}

variable "common_tags" {
  type = map(string)
}
