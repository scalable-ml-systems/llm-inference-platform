output "region" {
  value = var.region
}

output "cluster_name" {
  value = module.cluster_eks.cluster_name
}

output "cluster_endpoint" {
  value = module.cluster_eks.cluster_endpoint
}

output "oidc_provider_arn" {
  value = module.cluster_eks.oidc_provider_arn
}

output "vpc_id" {
  value = module.network_vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.network_vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.network_vpc.private_subnet_ids
}

output "gpu_nodegroup_name" {
  value = module.nodegroup_gpu.nodegroup_name
}

output "models_bucket_name" {
  value = aws_s3_bucket.models.bucket
}
