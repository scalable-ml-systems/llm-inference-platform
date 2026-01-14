variable "name" { type = string }
variable "kubernetes_version" { type = string }

variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }

variable "eks_cluster_role_arn" { type = string }

variable "tags" {
  type    = map(string)
  default = {}
}
