resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
  depends_on = [module.eks]
}

resource "helm_release" "kube_prometheus_stack" {
  name       = "monitoring"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = "56.0.0"

  depends_on = [module.eks, module.vpc]

  set {
    name  = "grafana.adminPassword"
    value = var.grafana_password
  }

  set {
    name  = "prometheus.prometheusSpec.resources.requests.memory"
    value = "512Mi"
  }
  set {
    name  = "prometheus.prometheusSpec.resources.limits.memory"
    value = "1024Mi"
  }
}
