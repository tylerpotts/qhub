resource "kubernetes_manifest" "kubecost-middleware" {
  provider = kubernetes-alpha

  manifest = {
    apiVersion = "traefik.containo.us/v1alpha1"
    kind       = "Middleware"
    metadata = {
      name      = "qhub-kubecost-middleware"
      namespace = kubernetes_namespace.kubecost.metadata[0].name
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