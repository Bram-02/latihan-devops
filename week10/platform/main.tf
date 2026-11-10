terraform {
  required_providers {
    kubernetes = { source = "hashicorp/kubernetes", version = "~> 3.5" }
    helm       = { source = "hashicorp/helm", version = "~> 3.0" }
  }
}

# Lapisan 1 -> lapisan 2: kubeconfig diambil dari output cluster, tidak diketik manual
data "terraform_remote_state" "cluster" {
  backend = "local"
  config = {
    path = "../cluster/terraform.tfstate"
  }
}

locals {
  kubeconfig_path = data.terraform_remote_state.cluster.outputs.kubeconfig_path
}

provider "kubernetes" {
  config_path = local.kubeconfig_path
}

provider "helm" {
  kubernetes = {
    config_path = local.kubeconfig_path
  }
}

variable "metrics_server_version" {
  type    = string
  default = "3.14.0"
}

variable "image_tag" {
  type        = string
  description = "Commit SHA image devops-website-bram"
}

# Lapisan 2: platform
resource "kubernetes_namespace_v1" "website" {
  metadata { name = "website" }
}

resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = var.metrics_server_version
  namespace  = "kube-system"

  set = [
    { name = "args[0]", value = "--kubelet-insecure-tls" }
  ]
}

# Lapisan 3: aplikasi
resource "kubernetes_deployment_v1" "website" {
  # Jumlah replika nanti diatur HPA (Week 15), bukan oleh kode
  lifecycle {
    ignore_changes = [spec[0].replicas]
  }

  metadata {
    name      = "website"
    namespace = kubernetes_namespace_v1.website.metadata[0].name
  }
  spec {
    replicas = 2
    selector { match_labels = { app = "website" } }
    template {
      metadata { labels = { app = "website" } }
      spec {
        container {
          name  = "web"
          image = "ghcr.io/bram-02/devops-website-bram:${var.image_tag}"
          port { container_port = 8080 }
          readiness_probe {
            http_get {
              path = "/"
              port = 8080
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "website" {
  metadata {
    name      = "website"
    namespace = kubernetes_namespace_v1.website.metadata[0].name
  }
  spec {
    selector = { app = "website" }
    port {
      port        = 80
      target_port = 8080
    }
  }
}
