# kubectl create namespace kubecost
# helm repo add kubecost https://kubecost.github.io/cost-analyzer/
# helm install kubecost kubecost/cost-analyzer --namespace kubecost --set kubecostToken="ZGxlc3RlckBxdWFuc2lnaHQuY29txm343yadf98"

#resource "kubernetes_namespace" "kubecost" {
#  metadata {
#    name = "${var.namespace}-kubecost"
#  }
#}

data "helm_repository" "kubecost" {
  name = "kubecost"
  url  = "https://kubecost.github.io/cost-analyzer/"
}

resource "helm_release" "kubecost" {
  name      = "kubecost"
  namespace = var.namespace  # kubernetes_namespace.kubecost.metadata[0].name

  repository = data.helm_repository.kubecost.metadata[0].name
  chart      = "kubecost/cost-analyzer"
  version    = "1.80.0"
}

resource "kubernetes_service" "kubecost" {
  metadata {
    name      = "service-kubecost"
    namespace = var.namespace  # kubernetes_namespace.kubecost.metadata[0].name
  }

  spec {
    selector = {
      "app.kubernetes.io/name" = "cost-analyzer"
    }

    port {
      name        = "dashboard"
      protocol    = "TCP"
      port        = 9090
      target_port = 9090
    }

    type = "ClusterIP"
  }
}