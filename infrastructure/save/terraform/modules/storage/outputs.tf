output "models_bucket_name" {
  value = aws_s3_bucket.models.bucket
}

output "fsx_id" {
  value = aws_fsx_lustre_file_system.fsx.id
}
