# https://aws.amazon.com/blogs/containers/introducing-efs-csi-dynamic-provisioning/
resource "aws_iam_policy" "efs-csi" {
  name        = "qonyx-dev-EFSCSIControllerIAMPolicy"
  path        = "/"
  description = "EFS CSI Driver Policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "elasticfilesystem:DescribeAccessPoints",
          "elasticfilesystem:DescribeFileSystems"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "elasticfilesystem:CreateAccessPoint"
        ]
        Effect   = "Allow"
        Resource = "*",
        Condition = {
          StringEquals = {
            "aws:RequestTag/efs.csi.aws.com/cluster" = "true"
          }
        }
      },
      {
        Action = [
          "elasticfilesystem:DeleteAccessPoint"
        ]
        Effect   = "Allow"
        Resource = "*",
        Condition = {
          StringEquals = {
            "aws:ResourceTag/efs.csi.aws.com/cluster" = "true"
          }
        }
      },
    ]
  })

  # tags = local.tags 		
}

resource "aws_iam_role_policy_attachment" "main-efs-csi" {
  # role       = module.eks.eks_managed_node_groups["default"].iam_role_name
  role       = "onyxq-dev-eks-node-group-role"
  policy_arn = aws_iam_policy.efs-csi.arn
}

# resource "aws_efs_file_system" "efs-csi" {
#   # creation_token                  = local.cluster_name
#   creation_token                  = "onyxq-dev"
#   throughput_mode                 = "provisioned"
#   provisioned_throughput_in_mibps = 10
#   encrypted                       = true
#   # tags                            = local.tags 
# }

# resource "aws_efs_mount_target" "efs-csi" {
#   count          = length(local.public_subnets)
#   file_system_id = aws_efs_file_system.efs-csi.id
#   subnet_id      = module.vpc.public_subnets[count.index]
#   security_groups = [module.eks.eks_managed_node_groups["default"].security_group_id]
# }

resource "aws_security_group_rule" "nfs" {
  from_port = 2049
  to_port   = 2049
  protocol  = "tcp"
  # security_group_id = module.eks.eks_managed_node_groups["default"].security_group_id
  security_group_id = "sg-02ef5c41302c56de3"
  type              = "ingress"
  cidr_blocks       = ["10.10.0.0/16"]
}
