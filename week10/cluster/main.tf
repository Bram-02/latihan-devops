terraform {
  required_providers {
    kind = { source = "tehcyx/kind", version = "~> 0.13.0" }
  }
}

resource "kind_cluster" "lab" {
  name           = "skomawan-lab"
  wait_for_ready = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"
    node { role = "control-plane" }
    node { role = "worker" }
    node { role = "worker" }
  }
}

output "kubeconfig_path" {
  value = kind_cluster.lab.kubeconfig_path
}
