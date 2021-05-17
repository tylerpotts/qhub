output "namespace" {
  description = "K8s namespace name for kubecost"
  value = kubernetes_namespace.kubecost.metadata[0].name
}
