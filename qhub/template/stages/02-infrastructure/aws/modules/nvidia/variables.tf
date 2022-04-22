variable "node_groups" {
  description = "Node groups to add to EKS Cluster"
  type = list(object({
    name          = string
    instance_type = string
    gpu           = bool
    min_size      = number
    desired_size  = number
    max_size      = number
  }))
}
