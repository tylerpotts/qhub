module "kubernetes-ingress" {
  source = "./modules/kubernetes/ingress"

  namespace = var.environment

  node-group = var.node_groups.general

  enable-certificates       = var.enable-certificates
  acme-email                = var.acme-email
  acme-server               = var.acme-server
  certificate-secret-name   = var.certificate-secret-name

  load_balancer_annotations = var.internal-load_balancer-annotations
  load_balancer_ip_address  = var.internal-load_balancer-ip_adress
}
