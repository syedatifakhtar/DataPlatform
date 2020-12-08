variable "eks-cw-logging" {
  default = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"]
  type = list(string)
  description = "Enable EKS CWL for EKS components"
}

variable "region" {
}

variable "cluster-name" {
}

variable "k8s-version" {
}

variable "security_group_ids" {
  type = list(string)
}


variable "private_subnet_ids" {
  type = list(string)
}
variable "public_subnet_ids" {}
variable "ip_whitelist" {
  type = list(string)
}

variable "kubeconfig_aws_authenticator_env_variables" {
  description = "Environment variables that should be used when executing the authenticator. e.g. { AWS_PROFILE = \"eks\"}."
  type = map(string)
  default = {}
}