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
  windows_image_id = "c3304694-a03f-47c7-8d4c-348eecc7d212"
}

module "windows_server_a" {
  source = "../modules/server"

  project_id             = stackit_resourcemanager_project.spoke.project_id
  network_id             = stackit_network.spoke_network.network_id
  availability_zone      = var.default_zone
  name                   = "windows-server-a"
  image_id               = local.windows_image_id
  machine_type           = "m2i.8"
  disk_size              = 100
  disk_performance_class = "storage_premium_perf2"
  user_data              = templatefile("${path.module}/../cloud-init/user-init-windows.yml", {})
}

module "windows_server_b" {
  source = "../modules/server"

  project_id             = stackit_resourcemanager_project.spoke.project_id
  network_id             = stackit_network.spoke_network.network_id
  availability_zone      = var.default_zone
  name                   = "windows-server-b"
  image_id               = local.windows_image_id
  machine_type           = "c2i.4"
  disk_size              = 100
  disk_performance_class = "storage_premium_perf1"
  user_data              = templatefile("${path.module}/../cloud-init/user-init-windows.yml", {})
}
