provider "kubernetes" {
  host                   = var.cluster_endpoint
  cluster_ca_certificate = base64decode(var.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", var.cluster_name]
  }
}

data "kubectl_file_documents" "crds" {
  content = file("${path.module}/templates/crds.yaml")
}

resource "kubectl_manifest" "crds" {
  for_each  = data.kubectl_file_documents.crds.manifests
  yaml_body = each.value
}

resource "time_sleep" "crds" {
  depends_on = [kubectl_manifest.crds]

  create_duration = "60s"
}