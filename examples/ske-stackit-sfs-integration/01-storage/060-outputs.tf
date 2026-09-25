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

# 02-cluster reads these through terraform_remote_state.
output "project_id" {
  description = "Project the cluster and the share live in."
  value       = stackit_resourcemanager_project.sfs.project_id
}

output "sfs_mount_path" {
  description = "Mount path of the SFS share, as <server>:<export path>."
  value       = stackit_sfs_share.sfs.mount_path
}

output "network_area_id" {
  description = "ID of the network area the projects are attached to"
  value       = stackit_network_area.sfs.network_area_id
}

output "sna_network_range" {
  description = "Range the network area hands out. The SFS export policy accepts clients from it."
  value       = var.sna_network_range
}
