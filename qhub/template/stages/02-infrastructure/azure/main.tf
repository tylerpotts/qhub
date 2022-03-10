resource "azurerm_resource_group" "resource_group" {
  name     = var.resource_group_name
  location = var.region
}


module "registry" {
  source              = "./modules/registry"

  name                = "${var.name}${var.environment}"
  location            = var.region
  resource_group_name = azurerm_resource_group.resource_group.name
}


module "kubernetes" {
  source = "./modules/kubernetes"

  name                     = "${var.name}-${var.environment}"
  environment              = var.environment
  location                 = var.region
  resource_group_name      = azurerm_resource_group.resource_group.name
  # Azure requires that a new, non-existent Resource Group is used, as otherwise
  # the provisioning of the Kubernetes Service will fail.
  node_resource_group_name = var.node_resource_group_name
  kubernetes_version       = var.kubernetes_version

  # Azure Vnet configuration
  enable_existing_vnet     = var.enable_existing_vnet
  vnet_name                = var.vnet_name
  subnet_name              = var.subnet_name
  vnet_security_group_name = var.vnet_resource_group

  node_groups = [
    for name, config in var.node_groups: {
      name          = name
      auto_scale    = true
      instance_type = config.instance
      min_size      = config.min_nodes
      max_size      = config.max_nodes
    }
  ]
}
