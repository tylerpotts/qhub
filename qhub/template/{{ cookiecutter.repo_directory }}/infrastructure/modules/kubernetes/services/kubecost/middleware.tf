resource "kubernetes_manifest" "kubecost-middleware" {
  provider = kubernetes-alpha

  manifest = {
    apiVersion = "traefik.containo.us/v1alpha1"
    kind       = "Middleware"
    metadata = {
      name      = "qhub-kubecost-middleware"
      namespace = "${var.namespace}-kubecost"
    }
    spec = {
      stripPrefixRegex = {
        regex = [
          "/kubecost"
        ]
      }
    }
  }
}