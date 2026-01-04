########################################################
# Observability: Prometheus, Grafana, Loki, DCGM exporter
########################################################

locals {
  name_prefix     = "${var.project}-${var.env}"
  monitoring_ns   = "monitoring"
  dcgm_namespace  = "gpu-metrics"
}

# Example: create namespaces for monitoring
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = local.monitoring_ns
  }
}

resource "kubernetes_namespace" "gpu_metrics" {
  metadata {
    name = local.dcgm_namespace
  }
}

# Helm release for kube-prometheus-stack (Prometheus + Grafana)
resource "helm_release" "kube_prometheus_stack" {
  name       = "kps"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "58.0.0"

  values = [
    file("${path.module}/values/kube-prometheus-stack-values.yaml")
  ]
}

# Loki (optional, stub)
resource "helm_release" "loki" {
  name       = "loki"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"
  version    = "6.6.0"

  values = [
    file("${path.module}/values/loki-values.yaml")
  ]
}

# DCGM exporter for GPU metrics
resource "helm_release" "dcgm_exporter" {
  name       = "dcgm-exporter"
  namespace  = kubernetes_namespace.gpu_metrics.metadata[0].name
  repository = "https://nvidia.github.io/dcgm-exporter"
  chart      = "dcgm-exporter"
  version    = "3.3.5"

  values = [
    file("${path.module}/values/dcgm-values.yaml")
  ]
}

# Dashboard JSONs (stubs) placed in dashboards/
# You can later wire them into Grafana via config maps or API calls.
