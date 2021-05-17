variable "namespace" {
  description = "Namespace of main deployment (kubecost namespace will be derived from this)"
  type        = string
}

variable "overrides" {
  description = "Kubecost helm chart list of overrides"
  type        = list(string)
  default     = []
}
