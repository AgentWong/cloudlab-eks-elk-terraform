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

data "kubectl_file_documents" "operator" {
  content = file("${path.module}/templates/operator.yaml")
}

resource "kubectl_manifest" "elastic_operator" {
  for_each  = data.kubectl_file_documents.operator.manifests
  yaml_body = each.value
}

resource "kubernetes_manifest" "elasticsearch" {
  manifest = yamldecode(file("${path.module}/templates/elasticsearch.yaml"))

  depends_on = [kubectl_manifest.elastic_operator]
}

resource "time_sleep" "elasticsearch" {
  depends_on = [kubernetes_manifest.elasticsearch]

  create_duration = "120s"
}

resource "kubernetes_manifest" "kibana" {
  manifest = yamldecode(file("${path.module}/templates/kibana.yaml"))

  depends_on = [time_sleep.elasticsearch]
}

resource "kubernetes_manifest" "logstash" {
  manifest = yamldecode(file("${path.module}/templates/logstash.yaml"))

  field_manager {
    force_conflicts = true
  }

  depends_on = [time_sleep.elasticsearch]
}