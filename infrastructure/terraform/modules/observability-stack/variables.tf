variable "name" {
  description = "Base name for the stack (used in resource names)."
  type        = string
  default     = "observability"
}

variable "namespace" {
  description = "Namespace where monitoring stack runs."
  type        = string
  default     = "monitoring"
}

variable "kube_prometheus_stack_version" {
  description = "Helm chart version for kube-prometheus-stack (optional)."
  type        = string
  default     = ""
}

variable "dcgm_exporter_version" {
  description = "Helm chart version for dcgm-exporter (optional)."
  type        = string
  default     = ""
}

variable "observability_dir" {
  description = "Path to services/observability directory (absolute or relative to this module)."
  type        = string
  default     = "../../../services/observability"
}

# If you label ServiceMonitors/PrometheusRules with release=<release_name>, set it here.
variable "kps_release_name" {
  description = "Helm release name for kube-prometheus-stack."
  type        = string
  default     = "kube-prometheus-stack"
}

# Prometheus operator selectors - allow selecting ServiceMonitors/Rules not created by Helm
variable "selector_nil_uses_helm_values" {
  description = "If false, Prometheus will select ServiceMonitors/Rules without requiring Helm release labels."
  type        = bool
  default     = false
}

# DCGM scheduling controls for GPU nodes
variable "dcgm_node_selector" {
  description = "Node selector map for dcgm-exporter."
  type        = map(string)
  default     = { workload = "gpu" }
}

variable "dcgm_tolerations" {
  description = "Tolerations for dcgm-exporter."
  type = list(object({
    key      = string
    operator = string
    value    = string
    effect   = string
  }))
  default = [
    {
      key      = "nvidia.com/gpu"
      operator = "Equal"
      value    = "present"
      effect   = "NoSchedule"
    }
  ]
}
