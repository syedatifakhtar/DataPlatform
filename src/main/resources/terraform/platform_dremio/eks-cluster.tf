resource "aws_eks_cluster" "eks" {
  name = var.cluster-name

  version = var.k8s-version

  role_arn = aws_iam_role.cluster.arn


  vpc_config {
    security_group_ids = var.security_group_ids
    subnet_ids         = [var.private_subnet_ids,var.public_subnet_ids]
    endpoint_public_access  = true
    public_access_cidrs     = var.ip_whitelist
  }


  enabled_cluster_log_types = var.eks-cw-logging


  depends_on = [
    aws_iam_role_policy_attachment.cluster-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster-AmazonEKSServicePolicy,
  ]
}


