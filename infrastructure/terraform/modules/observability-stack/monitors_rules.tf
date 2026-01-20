locals {
  scrape_dir = "${local.obs_dir}/prometheus/scrape-configs"
  rules_dir  = "${local.obs_dir}/prometheus/rules"

  scrape_files = fileset(local.scrape_dir, "*.yaml")
  rule_files   = fileset(local.rules_dir, "*.yaml")
}

resource "kubernetes_manifest" "scrape_configs" {
  for_each = { for f in local.scrape_files : f => f }

  manifest = yamldecode(file("${local.scrape_dir}/${each.key}"))
    
    depends_on = [null_resource.kube_prometheus_stack]
}

resource "kubernetes_manifest" "prom_rules" {
  for_each = { for f in local.rule_files : f => f }

  manifest = yamldecode(file("${local.rules_dir}/${each.key}"))

   depends_on = [null_resource.kube_prometheus_stack]
}
