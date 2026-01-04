output "example_ssm_parameter_name" {
  value = aws_ssm_parameter.example_config.name
}

output "example_secret_arn" {
  value = aws_secretsmanager_secret.example_secret.arn
}
