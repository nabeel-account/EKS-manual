#######################################################################################################################
# Role associated with the Node Group
#######################################################################################################################
# To provide instance group with pre-based worker nodes policies
resource "aws_iam_role" "nodes" {
  name = "eks-node-group-nodes"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}


#######################################################################################################################
# ESSENTIAL Node Group policies
#######################################################################################################################
# Attach the policies below to the node role

# Grants access to EC2 and EKS
resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.nodes.name
}

# CNI policy for inter node-to-node communication
resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.nodes.name
}

# Provides Access to EC2 container Registrtry (ECR)
resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.nodes.name
}


#######################################################################################################################
# NODE GROUP RESOURCES
#######################################################################################################################
resource "aws_eks_node_group" "private-nodes" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "private-nodes"
  node_role_arn   = aws_iam_role.nodes.arn

  subnet_ids = [
    aws_subnet.private_subnet_a.id,
    aws_subnet.private_subnet_b.id
  ]

  capacity_type  = "ON_DEMAND"
  instance_types = ["t3.medium"]

  # Cluster autoscaler needs to be deployed for this to take effect
  scaling_config {
    desired_size = 1
    max_size     = 5
    min_size     = 0
  }

  # Maximum number of unavailable worker nodes during upgrade
  update_config {
    max_unavailable = 1
  }

  labels = {
    role = "default"
  }

  ## Create Node Taint
  # taint {
  #   key    = "priority"
  #   value  = "high"
  #   effect = "NO_SCHEDULE"
  # }

  ## Add additional config like changing default ebs volume size or type - see below
  # launch_template {
  #   name    = aws_launch_template.eks-with-disks.name
  #   version = aws_launch_template.eks-with-disks.latest_version
  # }
  
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
  ]
}

## Update the EBS volume used by the EKS node groups
# resource "aws_launch_template" "eks-with-disks" {
#   name = "eks-with-disks"

#   key_name = "local-provisioner"

#   block_device_mappings {
#     device_name = "/dev/xvdb"

#     ebs {
#       volume_size = 50
#       volume_type = "gp2"
#     }
#   }
# }