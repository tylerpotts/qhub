variable "name" {
  description = "Prefix name to assign to azure kubernetes cluster"
  type        = string
}

# `az account list-locations`
variable "location" {
  description = "Location for GCP Kubernetes cluster"
  type        = string
}

variable "resource_group_name" {
  description = "name of qhub resource group"
  type        = string
}

variable "node_resource_group_name" {
  description = "name of new resource group for AKS nodes"
  type        = string
}

variable "kubernetes_version" {
  description = "Version of Kubernetes"
  type        = string
}

variable "environment" {
  description = "Location for GCP Kubernetes cluster"
  type        = string
}


variable "node_groups" {
  description = "Node pools to add to Azure Kubernetes Cluster"
  type        = list(map(any))
}

variable "tags" {
  description = "A mapping of tags which should be assigned to the Resource Group"
  type        = map(any)
  default     = {}
}

variable "rbac_enabled" {
  description = "value"
  type = map(any)
  default = {}
}
# {% if cookiecutter.azure.rbac.enabled %}
#   variable "AdminGroupObjectIDs" {
#     description = "RBAC Admin settings"
#     type = set(string)
#     default = []
#   }
# {% endif %}

variable "assign_vnet" {
  description = "Assign existing Virtual Network to cluster"
  type        = bool
  default     = false
}

variable "vnet_resource_group_name" {
  description = ""
  type        = string
  default     = "qhub-aks-vnet"
}

varaible "vnet_name" {
  description = ""
  type        = string
  default     = "aks-vnet"
}
