output "cicd_role_arn" {
  value = aws_iam_role.cicd.arn
}

output "artifact_bucket" {
  value = aws_s3_bucket.artifacts.bucket
}
