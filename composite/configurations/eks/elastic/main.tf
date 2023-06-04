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

resource "kubernetes_manifest" "elastic_crds" {
  manifest = yamldecode(file("${path.module}/templates/crds.yaml"))
}

resource "kubernetes_manifest" "elastic_operator" {
  manifest = yamldecode(file("${path.module}/templates/operator.yaml"))

  depends_on = [ kubernetes_manifest.elastic_crds ]
}

resource "time_sleep" "elastic_operator" {
    depends_on = [ kubernetes_manifest.elastic_operator ]

    create_duration = "60s"
}

resource "kubernetes_manifest" "elasticsearch" {
  manifest = yamldecode(file("${path.module}/templates/elasticsearch.yaml"))

  depends_on = [ time_sleep.elastic_operator ]
}