provider "azurerm" {
  features {}
}

{% if cookiecutter.azure.vnet is defined %}
# Import existing vnet
data "azurerm_virtual_network" "qhub-aks-vnet" {
  name                = "{{ cookiecutter.azure.vnet.name }}"
  resource_group_name = "{{ cookiecutter.azure.vnet.vnet_resource_group }}"
}

#subnet
resource "azurerm_subnet" "qhub-aks-subnet" {
  name                 = "{{ cookiecutter.azure.vnet.subnet_name }}"
  resource_group_name  = data.azurerm_virtual_network.qhub-aks-vnet.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.qhub-aks-vnet.name
  address_prefixes     = ["10.240.0.0/16"]
}
{% endif %}

module "registry" {
  source              = "./modules/azure/registry"
  name                = "{{ cookiecutter.project_name }}{{ cookiecutter.namespace }}"
  location            = "{{ cookiecutter.azure.region }}"
  resource_group_name = "{{ cookiecutter.project_name }}-{{ cookiecutter.namespace }}"
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
  resource_group_name      = "{{ cookiecutter.project_name }}-{{ cookiecutter.namespace }}"
  node_resource_group_name = "{{ cookiecutter.project_name }}-{{ cookiecutter.namespace }}-node-resource-group"
  kubernetes_version       = "{{ cookiecutter.azure.kubernetes_version }}"


{% if cookiecutter.azure.vnet is defined %}
  vnet_id                  = data.azurerm_virtual_network.qhub-aks-vnet.id
  subnet_id                = azurerm_subnet.qhub-aks-subnet.id
{% endif %}

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

{% if cookiecutter.azure.role_based_access_control is defined %}
rbac_enabled = {{ cookiecutter.azure.role_based_access_control.enabled }}
{% if cookiecutter.azure.role_based_access_control.azure_active_directory is defined %}
admin_group_object_ids = {{ cookiecutter.azure.role_based_access_control.azure_active_directory.admin_group_object_ids | jsonify }}
{% endif %}
{% endif %}

}
