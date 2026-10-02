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

module "server_a" {
  source = "../modules/server"

  project_id             = stackit_resourcemanager_project.spoke.project_id
  network_id             = stackit_network.spoke_network.network_id
  image_id               = var.linux_image_id
  availability_zone      = var.default_zone
  name                   = "server-a"
  machine_type           = "c2i.2"
  disk_size              = 50
  disk_performance_class = "storage_premium_perf1"
  user_data              = templatefile("${path.module}/../cloud-init/user-init-linux.yml", {})
}

module "server_b" {
  source = "../modules/server"

  project_id             = stackit_resourcemanager_project.spoke.project_id
  network_id             = stackit_network.spoke_network.network_id
  image_id               = var.linux_image_id
  availability_zone      = var.default_zone
  name                   = "server-b"
  machine_type           = "m2a.8d"
  disk_size              = 100
  disk_performance_class = "storage_premium_perf1"
  user_data              = templatefile("${path.module}/../cloud-init/user-init-linux.yml", {})
}
