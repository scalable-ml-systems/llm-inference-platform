output "vllm_repository_url" {
  value = aws_ecr_repository.vllm.repository_url
}

output "vllm_repository_arn" {
  value = aws_ecr_repository.vllm.arn
}

output "router_repository_url" {
  value = aws_ecr_repository.router.repository_url
}
