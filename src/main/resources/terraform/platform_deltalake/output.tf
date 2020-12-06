output "emr_ssh_key" {
  value = aws_ssm_parameter.cluster_private_key.value
}

output "emr_master_node_dns" {
  value = aws_emr_cluster.cluster.master_public_dns
}