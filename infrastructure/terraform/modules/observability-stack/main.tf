locals {
  obs_dir = abspath("${path.module}/${var.observability_dir}")
}

# Install kube-prometheus-stack via Helm CLI
resource "null_resource" "kube_prometheus_stack" {
  triggers = {
    namespace        = var.namespace
    release          = var.kps_release_name
    selector_nil     = tostring(var.selector_nil_uses_helm_values)
    # Bump this string if you want to force a reinstall
    revision         = "v1"
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1 || true
      helm repo update >/dev/null 2>&1

      helm upgrade --install ${var.kps_release_name} prometheus-community/kube-prometheus-stack \
        --namespace ${var.namespace} --create-namespace \
        --set grafana.enabled=true \
        --set alertmanager.enabled=true \
        --set grafana.sidecar.dashboards.enabled=true \
        --set grafana.sidecar.dashboards.label=grafana_dashboard \
        --set grafana.sidecar.datasources.enabled=true \
        --set grafana.sidecar.datasources.label=grafana_datasource \
        --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=${var.selector_nil_uses_helm_values} \
        --set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=${var.selector_nil_uses_helm_values} \
        --set prometheus.prometheusSpec.ruleSelectorNilUsesHelmValues=${var.selector_nil_uses_helm_values}
    EOT
    interpreter = ["/bin/bash", "-lc"]
  }

  depends_on = []
}

# Install dcgm-exporter via Helm CLI
resource "null_resource" "dcgm_exporter" {
  triggers = {
    namespace = var.namespace
    # Force updates on selector/toleration changes by bumping revision if needed
    revision  = "v1"
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      helm repo add nvidia https://nvidia.github.io/dcgm-exporter/helm-charts >/dev/null 2>&1 || true
      helm repo update >/dev/null 2>&1

      helm upgrade --install dcgm-exporter nvidia/dcgm-exporter \
        --namespace ${var.namespace} \
        --set serviceMonitor.enabled=true \
        --set resources.requests.memory=256Mi \
        --set resources.limits.memory=1Gi \
        --set nodeSelector.workload=gpu \
        --set tolerations[0].key="nvidia.com/gpu" \
        --set tolerations[0].operator="Equal" \
        --set tolerations[0].value="present" \
        --set tolerations[0].effect="NoSchedule"
    EOT
    interpreter = ["/bin/bash", "-lc"]
  }

  depends_on = [null_resource.kube_prometheus_stack]
}
