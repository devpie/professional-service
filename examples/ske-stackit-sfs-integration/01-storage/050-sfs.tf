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

locals {
  # Only workload inside the network area may mount the share.
  sfs_ip_acl = var.sfs_ip_acl != null ? var.sfs_ip_acl : [var.sna_network_range]
}

# The resource pool holds the capacity. Shares are carved out of it.
resource "stackit_sfs_resource_pool" "sfs" {
  project_id        = stackit_resourcemanager_project.sfs.project_id
  name              = "sfs-resourcepool"
  availability_zone = var.sfs_availability_zone
  performance_class = var.sfs_performance_class
  size_gigabytes    = var.sfs_pool_size_gigabytes
  ip_acl            = local.sfs_ip_acl

  snapshots_are_visible = true
  labels                = var.sfs_labels

  timeouts = {
    create = var.sfs_pool_operation_timeout
    update = var.sfs_pool_operation_timeout
    delete = var.sfs_pool_operation_timeout
  }
}

# The export policy decides who may mount a share and with which rights. A rule
# that omits super_user takes the API default, which is documented as root access
# granted. Set super_user = false to squash root for the matching clients.
resource "stackit_sfs_export_policy" "sfs" {
  project_id = stackit_resourcemanager_project.sfs.project_id
  name       = "example"
  labels     = var.sfs_labels
  rules = [
    {
      ip_acl      = local.sfs_ip_acl
      order       = 1
      description = "Read and write access for the network area"
    }
  ]
}

resource "stackit_sfs_share" "sfs" {
  project_id                 = stackit_resourcemanager_project.sfs.project_id
  resource_pool_id           = stackit_sfs_resource_pool.sfs.resource_pool_id
  name                       = "nfs-share"
  export_policy              = stackit_sfs_export_policy.sfs.name
  space_hard_limit_gigabytes = var.sfs_share_size_gigabytes
  labels                     = var.sfs_labels
}
