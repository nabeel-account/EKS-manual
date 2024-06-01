#######################################################################################################################
# Role associated with the EKS CLUSTER
#######################################################################################################################
# Provide EKS cluster with all the pre-baked Amazon EKS Cluster Policy.
# - necessary permissions e.g. connecting with AWS autoscaling
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
  # version = "1.29"

  vpc_config {
    subnet_ids = [
      aws_subnet.public_subnet_a.id,
      aws_subnet.public_subnet_b.id,
      aws_subnet.private_subnet_a.id,
      aws_subnet.private_subnet_b.id
    ]
  }

  depends_on = [aws_iam_role_policy_attachment.main-AmazonEKSClusterPolicy]
}