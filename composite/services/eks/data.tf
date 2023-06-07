data "aws_ami" "eks_default" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amazon-eks-node-${var.cluster_version}-v*"]
  }
}
data "aws_caller_identity" "current" {}

data "utils_aws_eks_update_kubeconfig" "eks" {
  profile = "default"
  kubeconfig  = "~/.kube/config"
  cluster_name = module.eks.cluster_name
  region      = var.region

  depends_on = [ module.eks ]
}

data "external" "list_hosted_zones" {
  program = ["sh", "-c", "aws route53 list-hosted-zones | jq -r '[.HostedZones[]] | map({ Name: .Name}) | .[]'"]

  # Note: Converting the resulting complex json object to a single property object that looks like this:
  #{
  #  "Name": "cmcloudlab944.info."
  #}

}