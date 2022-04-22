locals {
  gpu_node_group_names = [for node_group in var.node_groups : node_group.name if node_group.gpu == true]
}
