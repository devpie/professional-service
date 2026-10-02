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

resource "stackit_ske_cluster" "this" {
  project_id             = var.project_id
  name                   = "ske-gpu"
  kubernetes_version_min = var.kubernetes_version_min

  # Without os_version_min, the provider selects the newest supported image of os_name.
  node_pools = [
    {
      name               = "standard"
      machine_type       = "g2i.4"
      minimum            = "3"
      maximum            = "9"
      max_surge          = "3"
      availability_zones = [for z in [1, 2, 3] : "${var.stackit_region}-${z}"]
      os_name            = "flatcar"
      volume_size        = 150
      volume_type        = "storage_premium_perf6"
    },
    {
      name               = "gpu-pool-h100-2"
      machine_type       = "n3.14d.g1"
      os_name            = "ubuntu"
      minimum            = "1"
      maximum            = "1"
      max_surge          = "1"
      availability_zones = ["${var.stackit_region}-2"]
      volume_size        = 150
      volume_type        = "storage_premium_perf6"
      labels = {
        "dedicated" = "gpu"
      }
      taints = [
        {
          effect = "NoSchedule"
          key    = "nvidia.com/gpu"
          value  = "true"
        },
      ]
    },
  ]
}

resource "stackit_ske_kubeconfig" "this" {
  project_id   = var.project_id
  cluster_name = stackit_ske_cluster.this.name
  refresh      = true

  depends_on = [stackit_ske_cluster.this]
}
