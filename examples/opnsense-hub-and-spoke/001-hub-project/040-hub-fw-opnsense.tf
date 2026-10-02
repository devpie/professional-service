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

# Upload VPN Appliance Image to STACKIT.
# The provider checks during plan that the file exists, so download it first (see README.md).
resource "stackit_image" "opnsense_image" {
  project_id      = local.hub_project_id
  name            = "opnsense-26.1-amd64-image"
  local_file_path = var.opnsense_image_path
  disk_format     = "qcow2"
  min_disk_size   = 16
  min_ram         = 2
  config = {
    uefi = false
  }
}

resource "stackit_volume" "opnsense_volume" {
  project_id        = local.hub_project_id
  name              = "opnsense-root"
  availability_zone = var.default_zone
  size              = 16
  performance_class = "storage_premium_perf4"
  source = {
    id   = stackit_image.opnsense_image.image_id
    type = "image"
  }
}

resource "stackit_server" "opnsense" {
  project_id        = local.hub_project_id
  name              = "opnsense"
  availability_zone = var.default_zone
  machine_type      = var.opnsense_machine_type
  boot_volume = {
    source_type = "volume"
    source_id   = stackit_volume.opnsense_volume.volume_id
  }
  # Default OPNsense credentials:
  #   Username: root
  #   Password: STACKIT123!
  # WAN boots first (vtnet0); LAN and MGMT are attached in order below → vtnet1–2.
  network_interfaces = [stackit_network_interface.nic_wan.network_interface_id]
}

resource "stackit_server_network_interface_attach" "attach_lan" {
  project_id           = local.hub_project_id
  server_id            = stackit_server.opnsense.server_id
  network_interface_id = stackit_network_interface.nic_lan.network_interface_id
  depends_on           = [stackit_server.opnsense]
}

resource "stackit_server_network_interface_attach" "attach_mgmt" {
  project_id           = local.hub_project_id
  server_id            = stackit_server.opnsense.server_id
  network_interface_id = stackit_network_interface.nic_mgmt.network_interface_id
  depends_on           = [stackit_server_network_interface_attach.attach_lan]
}

resource "stackit_public_ip" "wan_public_ip" {
  project_id           = local.hub_project_id
  network_interface_id = stackit_network_interface.nic_wan.network_interface_id
}

resource "stackit_public_ip" "mgmt_public_ip" {
  project_id           = local.hub_project_id
  network_interface_id = stackit_network_interface.nic_mgmt.network_interface_id
}
