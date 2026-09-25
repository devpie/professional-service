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

# Reads the outputs of 01-storage. The count skips that when both values are
# given explicitly.
data "terraform_remote_state" "storage" {
  count = var.stackit_project_id == null || var.sfs_mount_path == null ? 1 : 0

  backend = "local"
  config = {
    path = var.storage_state_path
  }
}

locals {
  storage_outputs = one(data.terraform_remote_state.storage[*].outputs)

  stackit_project_id = coalesce(
    var.stackit_project_id,
    try(local.storage_outputs.project_id, null),
  )

  sfs_mount_path = coalesce(
    var.sfs_mount_path,
    try(local.storage_outputs.sfs_mount_path, null),
  )
}
