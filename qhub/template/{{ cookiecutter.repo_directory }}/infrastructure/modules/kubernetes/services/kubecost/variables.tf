variable "namespace" {
  description = "Namespace for Kubecost deployment"
  type        = string
}

variable "overrides" {
  description = "Kubecost helm chart list of overrides"
  type        = list(string)
  default     = []
}
