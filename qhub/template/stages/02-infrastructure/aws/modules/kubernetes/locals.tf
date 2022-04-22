locals {
  cluster_policies = concat([
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  ], var.cluster_additional_policies)

  node_group_policies = concat([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    aws_iam_policy.worker_autoscaling.arn
  ], var.node_group_additional_policies)

