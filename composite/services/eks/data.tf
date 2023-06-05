data "aws_ami" "eks_default" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amazon-eks-node-${var.cluster_version}-v*"]
  }
}
data "aws_caller_identity" "current" {}

provider "utils" {
  # no provider-specific config
}
data "utils_aws_eks_update_kubeconfig" "eks" {
  kubeconfig  = "~/.kube/config"
  cluster_name = module.eks.cluster_name
  region      = var.region
}