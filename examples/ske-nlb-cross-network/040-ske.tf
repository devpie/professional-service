# Copyright 2026 Schwarz Digits Cloud GmbH & Co. KG
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# ── Kubernetes version data source ─────────────────────────────────

data "stackit_ske_kubernetes_versions" "latest" {
  version_state = "SUPPORTED"
}

# ── SKE Cluster ────────────────────────────────────────────────────

resource "stackit_ske_cluster" "main" {
  project_id             = stackit_resourcemanager_project.ske_project.project_id
  name                   = var.cluster_name
  kubernetes_version_min = var.cluster_kubernetes_version
  node_pools = [
    {
      name               = "workers"
      machine_type       = var.node_pool_machine_type
      minimum            = var.node_pool_minimum
      maximum            = var.node_pool_maximum
      availability_zones = var.node_pool_availability_zones
      os_name            = "flatcar"
      volume_size        = var.node_pool_volume_size
      volume_type        = var.node_pool_volume_type
    },
  ]

  network = {
    id = stackit_network.ske_network.network_id
  }

  lifecycle {
    ignore_changes = [
      kubernetes_version_min,
      node_pools,
    ]
  }
}

# ── Kubeconfig ─────────────────────────────────────────────────────

resource "stackit_ske_kubeconfig" "ske" {
  project_id   = stackit_resourcemanager_project.ske_project.project_id
  cluster_name = stackit_ske_cluster.main.name
  refresh      = true
  expiration   = 7200
}
