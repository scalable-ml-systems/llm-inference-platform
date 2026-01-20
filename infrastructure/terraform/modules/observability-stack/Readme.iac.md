# observability-stack Terraform module

Installs:
- kube-prometheus-stack (Prometheus Operator, Prometheus, Grafana, Alertmanager)
- dcgm-exporter (GPU metrics) with ServiceMonitor enabled

Applies repo config from:
- services/observability/prometheus/scrape-configs/*.yaml
- services/observability/prometheus/rules/*.yaml
- services/observability/grafana/dashboards/*.json
- services/observability/grafana/provisioning/datasources/*.yaml

## Usage
module "observability" {
  source = "../../modules/observability-stack"

  namespace         = "monitoring"
  kps_release_name  = "kube-prometheus-stack"
  observability_dir = "../../../services/observability"

  # Recommended: allow ServiceMonitors/Rules without requiring release labels
  selector_nil_uses_helm_values = false
}

## Verify
kubectl -n monitoring get pods
kubectl -n monitoring get servicemonitor
kubectl -n monitoring get prometheusrule

kubectl -n monitoring port-forward svc/kube-prometheus-stack-prometheus 9090:9090
kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80
