terraform {
  required_providers {
    kubernetes = { source = "hashicorp/kubernetes", version = "~> 3.5" }
    helm       = { source = "hashicorp/helm", version = "~> 3.0" }
  }
}

# Lapisan 1 tetap dari week10/cluster
data "terraform_remote_state" "cluster" {
  backend = "local"
  config = {
    path = "../../week10/cluster/terraform.tfstate"
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

variable "argocd_chart_version" {
  type    = string
  default = "10.17.1"
}

# Lapisan 2: platform
resource "kubernetes_namespace_v1" "website" {
  metadata { name = "website" }
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_chart_version
  namespace        = "argocd"
  create_namespace = true
  timeout          = 900

  set = [
    { name = "dex.enabled", value = "false" },
    { name = "notifications.enabled", value = "false" },
  ]
}

# Lapisan 3 (Deployment, Service website) TIDAK ditulis di sini:
# pemiliknya Argo CD, dari repository Git (satu objek, satu pemilik).
