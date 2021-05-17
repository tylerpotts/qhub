resource "kubernetes_service" "forwardauth-service" {
  metadata {
    name = "forwardauth-service"
    namespace = var.namespace
  }
  spec {
    selector = {
      app = kubernetes_deployment.forwardauth-deployment.spec.0.template.0.metadata[0].labels.app
    }
    port {
      port        = 4181
      target_port = 4181
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_deployment" "forwardauth-deployment" {
  metadata {
    name      = "forwardauth-deployment"
    namespace = var.namespace
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "forwardauth-pod"
      }
    }

    template {
      metadata {
        labels = {
          app = "forwardauth-pod"
        }
      }

      spec {

        container {
          name  = "forwardauth-container"
          image = "thomseddon/traefik-forward-auth:2"

          env {
            name = "PROVIDERS_GENERIC_OAUTH_AUTH_URL"
            value = "https://github.com/login/oauth/authorize"
          }

          env {
            name = "PROVIDERS_GENERIC_OAUTH_TOKEN_URL"
            value = "https://github.com/login/oauth/access_token"
          }

          env {
            name = "PROVIDERS_GENERIC_OAUTH_USER_URL"
            value = "https://api.github.com/user"
          }

          env {
            name = "PROVIDERS_GENERIC_OAUTH_CLIENT_ID"
            value = ""
          }

          env {
            name = "PROVIDERS_GENERIC_OAUTH_CLIENT_SECRET"
            value = ""
          }

          env {
            name = "SECRET"
            value = ""
          }

          env {
            name = "DEFAULT_PROVIDER"
            value = "generic-oauth"
          }

          env {
            name = "URL_PATH"
            value = "/forwardauth/_oauth"
          }

          env {
            name = "LOG_LEVEL"
            value = "debug"
          }

          port {
            container_port = 4181
          }

        }

      }
    }
  }
}

resource "kubernetes_manifest" "forwardauth-middleware" {
  # This version of the middleware is primarily for the forwardauth service
  # itself, so the callback _oauth url can be centalised (not just under e.g. /kubecost/_oauth).
  # This middleware is in the root namespace, kubecost may have its own.

  provider = kubernetes-alpha

  manifest = {
    apiVersion = "traefik.containo.us/v1alpha1"
    kind       = "Middleware"
    metadata = {
      name      = "traefik-forward-auth"
      namespace = var.namespace
    }
    spec = {
      forwardAuth = {
        address = "http://forwardauth-service:4181"
        authResponseHeaders = [
            "X-Forwarded-User"
        ]
      }
    }
  }
}

