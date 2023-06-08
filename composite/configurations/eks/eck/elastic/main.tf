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

resource "kubernetes_manifest" "elastic_operator_namespace" {
  manifest = yamldecode(file("${path.module}/templates/operator-namespace.yaml"))
}

data "kubectl_file_documents" "operator" {
  content = file("${path.module}/templates/operator.yaml")
}

resource "kubernetes_manifest" "elastic_operator" {
  for_each = data.kubectl_file_documents.operator.manifests
  manifest = yamldecode(each.value)

  depends_on = [kubernetes_manifest.elastic_operator_namespace]
}

resource "kubernetes_manifest" "elasticsearch" {
  manifest = yamldecode(file("${path.module}/templates/elasticsearch.yaml"))

  field_manager {
    force_conflicts = true
  }

  wait {
    fields = {
      # Check the phase of a pod
      "status.health" = "green"
    }
  }

  depends_on = [kubernetes_manifest.elastic_operator]
}

resource "kubernetes_manifest" "kibana" {
  manifest = yamldecode(file("${path.module}/templates/kibana.yaml"))

  wait {
    fields = {
      # Check the phase of a pod
      "status.health" = "green"
    }
  }

  depends_on = [kubernetes_manifest.elasticsearch]
}

resource "kubernetes_manifest" "logstash" {
  manifest = yamldecode(file("${path.module}/templates/logstash.yaml"))

  field_manager {
    force_conflicts = true
  }

  depends_on = [kubernetes_manifest.kibana]
}

data "kubectl_file_documents" "fleetserver" {
  content = file("${path.module}/templates/fleetserver.yaml")
}

resource "kubernetes_manifest" "fleetserver" {
  for_each = data.kubectl_file_documents.fleetserver.manifests
  manifest = yamldecode(each.value)

  depends_on = [kubernetes_manifest.kibana]
}