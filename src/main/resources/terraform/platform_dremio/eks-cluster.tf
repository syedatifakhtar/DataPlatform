resource "aws_eks_cluster" "eks" {
  name = var.cluster-name

  version = var.k8s-version

  role_arn = aws_iam_role.cluster.arn


  vpc_config {
    security_group_ids = var.security_group_ids
    subnet_ids         = var.eks_subnet_ids
    endpoint_public_access  = true
    public_access_cidrs     = var.ip_whitelist
  }

  enabled_cluster_log_types = var.eks-cw-logging


  depends_on = [
    aws_iam_role_policy_attachment.cluster-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster-AmazonEKSServicePolicy,
  ]
}


locals {
  kubeconfig =  templatefile("${path.module}/templates/kubeconfig.tpl", {
    kubeconfig_name                   = "eks_${var.cluster-name}"
    endpoint                          = coalescelist(aws_eks_cluster.eks[*].endpoint, [""])[0]
    cluster_auth_base64               = coalescelist(aws_eks_cluster.eks[*].certificate_authority[0].data, [""])[0]
    aws_authenticator_command         = "aws-iam-authenticator"
    aws_authenticator_command_args    = ["token", "-i", coalescelist(aws_eks_cluster.eks[*].name, [""])[0]]
    aws_authenticator_additional_args = []
    aws_authenticator_env_variables   = var.kubeconfig_aws_authenticator_env_variables
  })
}