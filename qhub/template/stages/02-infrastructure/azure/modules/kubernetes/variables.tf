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

variable "enable_existing_vnet" {
  description = "Specifies whether to use an existing Virtual Network"
  type        = boolean
  default     = false
}

variable "vnet_security_group_name" {
  description = "The name of the VNet Security Group"
  type        = string
}

variable "vnet_name" {
  description = "The name of the VNet"
  type        = string
}

variable "subnet_name" {
  description = "The name of the Subnet"
  type        = string
}
