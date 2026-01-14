output "cluster_role_arn" {
  value = aws_iam_role.cluster.arn
}

output "node_role_arn" {
  value = aws_iam_role.nodes.arn
}

output "vllm_irsa_role_arn" {
  value = aws_iam_role.vllm_irsa.arn
}

output "fsx_csi_irsa_role_arn" {
  value = aws_iam_role.fsx_csi_irsa.arn
}

output "prometheus_irsa_role_arn" {
  value = aws_iam_role.prometheus_irsa.arn
}

output "cluster_autoscaler_role_arn" {
  value = aws_iam_role.cluster_autoscaler_irsa.arn
}
