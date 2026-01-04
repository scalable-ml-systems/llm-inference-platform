output "monitoring_namespace" {
  value = kubernetes_namespace.monitoring.metadata[0].name
}

output "gpu_metrics_namespace" {
  value = kubernetes_namespace.gpu_metrics.metadata[0].name
}
