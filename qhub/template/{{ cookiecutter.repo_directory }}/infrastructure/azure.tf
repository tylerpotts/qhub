provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "resource_group" {
  name     = var.resource_group_name
  location = var.region
}

module "registry" {
  source              = "./modules/azure/registry"
  name                = var.qhub_registry_name
  location            = "{{ cookiecutter.azure.region }}"
  resource_group_name = azurerm_resource_group.resource_group.name

{% if cookiecutter.azure.tags is defined %}
  tags = {
{% for name, value in cookiecutter.azure.tags.items() %}
    "{{ name }}" = "{{ value }}",
{% endfor %}
  }
{% endif %}
}

module "kubernetes" {
  source = "./modules/azure/kubernetes"

  name                     = local.cluster_name
  environment              = var.environment
  location                 = var.region
  resource_group_name      = azurerm_resource_group.resource_group.name
  node_resource_group_name = var.resource_node_group_name
  kubernetes_version       = "{{ cookiecutter.azure.kubernetes_version }}"

  node_groups = [
{% for nodegroup, nodegroup_config in cookiecutter.azure.node_groups.items() %}
    {
      name          = "{{ nodegroup }}"
      auto_scale    = true
      instance_type = "{{ nodegroup_config.instance }}"
      min_size      = {{ nodegroup_config.min_nodes }}
      max_size      = {{ nodegroup_config.max_nodes }}
    },
{% endfor %}
  ]

{% if cookiecutter.azure.tags is defined %}
  tags = {
{% for name, value in cookiecutter.azure.tags.items() %}
    "{{ name }}" = "{{ value }}",
{% endfor %}
  }
{% endif %}

}
