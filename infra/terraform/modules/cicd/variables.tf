variable "env" {
  type = string
}

variable "project" {
  type = string
}

variable "github_org" {
  type = string
}

variable "github_repo" {
  type = string
}

variable "vllm_ecr_arn" {
  type = string
}

variable "common_tags" {
  type = map(string)
}
