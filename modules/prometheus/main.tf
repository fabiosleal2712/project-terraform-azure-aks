resource "null_resource" "prometheus" {
  provisioner "local-exec" {
    command = <<EOT
      kubectl config set-context --current --namespace=default
      kubectl apply --validate=false -f modules/prometheus/prometheus-deployment.yaml
    EOT
  }

  triggers = {
    always_run = "${timestamp()}"
  }
}

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
      configuration_aliases = [
        kubernetes.k8s,
      ]
    }
  }
}