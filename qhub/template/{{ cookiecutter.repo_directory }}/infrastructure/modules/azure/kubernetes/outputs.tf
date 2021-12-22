output "credentials" {
  description = "Credentials required for connecting to kubernetes cluster"
  value = {
    # see bottom of https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster
    # If RBAC enabled, switch credentials to kube_Admin
    endpoint               = var.rbac_enabled ? azurerm_kubernetes_cluster.main.kube_admin_config.0.host : azurerm_kubernetes_cluster.main.kube_config.0.host
    username               = var.rbac_enabled ? azurerm_kubernetes_cluster.main.kube_admin_config.0.username : azurerm_kubernetes_cluster.main.kube_config.0.username
    password               = var.rbac_enabled ? azurerm_kubernetes_cluster.main.kube_admin_config.0.password : azurerm_kubernetes_cluster.main.kube_config.0.password
    client_certificate     = var.rbac_enabled ? base64decode(azurerm_kubernetes_cluster.main.kube_admin_config.0.client_certificate) : base64decode(azurerm_kubernetes_cluster.main.kube_config.0.client_certificate)
    client_key             = var.rbac_enabled ? base64decode(azurerm_kubernetes_cluster.main.kube_admin_config.0.client_key) : base64decode(azurerm_kubernetes_cluster.main.kube_config.0.client_key)
    cluster_ca_certificate = var.rbac_enabled ? base64decode(azurerm_kubernetes_cluster.main.kube_admin_config.0.cluster_ca_certificate) : base64decode(azurerm_kubernetes_cluster.main.kube_config.0.cluster_ca_certificate)
  }
}
