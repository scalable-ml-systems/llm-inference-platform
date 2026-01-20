locals {
  dashboards_dir  = "${local.obs_dir}/grafana/dashboards"
  datasources_dir = "${local.obs_dir}/grafana/provisioning/datasources"

  dashboard_files  = fileset(local.dashboards_dir, "*.json")
  datasource_files = fileset(local.datasources_dir, "*.yaml")
}

resource "kubernetes_config_map_v1" "grafana_dashboards" {
  for_each = { for f in local.dashboard_files : f => f }

  metadata {
    name      = "grafana-dashboard-${replace(each.key, ".json", "")}"
    namespace = var.namespace
    labels = {
      grafana_dashboard = "1"
    }
  }

  data = {
    (each.key) = file("${local.dashboards_dir}/${each.key}")
  }

    depends_on = [null_resource.kube_prometheus_stack]
}

resource "kubernetes_config_map_v1" "grafana_datasources" {
  for_each = { for f in local.datasource_files : f => f }

  metadata {
    name      = "grafana-datasource-${replace(each.key, ".yaml", "")}"
    namespace = var.namespace
    labels = {
      grafana_datasource = "1"
    }
  }

  data = {
    (each.key) = file("${local.datasources_dir}/${each.key}")
  }

    depends_on = [null_resource.kube_prometheus_stack]
}
