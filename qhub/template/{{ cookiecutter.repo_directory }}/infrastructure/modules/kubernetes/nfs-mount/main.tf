resource "kubernetes_storage_class" "main" {
  metadata {
    name = "${var.name}-${var.namespace}-share"
  }

  storage_provisioner = "kubernetes.io/fake-nfs"
}


resource "kubernetes_persistent_volume" "main" {
  metadata {
    name = "${var.name}-${var.namespace}-share"
  }
  spec {
    capacity = {
      storage = var.nfs_capacity
    }
    storage_class_name = kubernetes_storage_class.main.metadata.0.name
    access_modes       = ["ReadWriteMany"]
    node_affinity {
      required {
        node_selector_term {
          match_expressions {
            key      = var.node-group.key
            operator = "In"
            values = [
              var.node-group.value
            ]
          }
        }
      }
    }
    persistent_volume_source {
      nfs {
        path   = "/"
        server = var.nfs_endpoint
      }
    }
  }
}


resource "kubernetes_persistent_volume_claim" "main" {
  metadata {
    name      = "${var.name}-${var.namespace}-share"
    namespace = var.namespace
  }

  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = kubernetes_storage_class.main.metadata.0.name
    resources {
      requests = {
        storage = var.nfs_capacity
      }
    }
  }
}
