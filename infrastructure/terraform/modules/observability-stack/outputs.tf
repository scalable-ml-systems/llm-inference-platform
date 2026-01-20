output "namespace" {
  value = var.namespace
}

output "prometheus_service" {
  value = "svc/${var.kps_release_name}-prometheus"
}

output "grafana_service" {
  value = "svc/${var.kps_release_name}-grafana"
}
