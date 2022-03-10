variable "name" {
  description = "Prefix name to azure container registry"
  type        = string
}

variable "location" {
  description = "Location of qhub resource group"
  type        = string
}

variable "resource_group_name" {
  description = "name of qhub resource group"
  type        = string
}

variable "tags" {
  description = "A mapping of tags to be assigned to the resources"
  type        = map(any)
  default     = {}
}
