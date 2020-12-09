output "eks_endpoint" {
  value = aws_eks_cluster.eks.endpoint
}

output "eks_kubeconfig" {
  value = local.kubeconfig
}