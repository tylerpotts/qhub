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

resource "kubernetes_manifest" "forwardauth-middleware" {
  provider = kubernetes-alpha

  manifest = {
    apiVersion = "traefik.containo.us/v1alpha1"
    kind       = "Middleware"
    metadata = {
      name      = "traefik-forward-auth"
      namespace = kubernetes_namespace.kubecost.metadata[0].name
    }
    spec = {
      forwardAuth = {
        address = "http://forwardauth-service.${var.namespace}:4181"
        authResponseHeaders = [
            "X-Forwarded-User"
        ]
      }
    }
  }
}
