#######################################################################################################################
# Role associated with the EKS CLUSTER
#######################################################################################################################
# Action = pricniple user is able to assume other roles.
resource "aws_iam_role" "main" {
  name = "eks-cluster-main"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

# Attached the required policy to the role
resource "aws_iam_role_policy_attachment" "main-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.main.name
}


#######################################################################################################################
# CREATE EKS CLUSTER
#######################################################################################################################
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.main.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.my_public_subnet_1.id,
      aws_subnet.my_public_subnet_2.id,
      aws_subnet.my_private_subnet_2.id,
      aws_subnet.my_private_subnet_2.id
    ]
  }

  depends_on = [aws_iam_role_policy_attachment.main-AmazonEKSClusterPolicy]
}