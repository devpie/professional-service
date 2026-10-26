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

// servers with nginx as ALB backends
resource "stackit_server" "srv" {
  for_each          = var.servers
  project_id        = local.project_id
  name              = each.key
  availability_zone = each.value
  machine_type      = var.flavor
  keypair_name      = stackit_key_pair.keypair.name
  boot_volume = {
    source_type           = "image"
    source_id             = data.stackit_image.debian.image_id
    size                  = 20
    delete_on_termination = true
  }
  // LAN interface first (default route), management interface only on var.ssh_server
  network_interfaces = concat(
    [stackit_network_interface.srv[each.key].network_interface_id],
    each.key == var.ssh_server ? [stackit_network_interface.mgmt.network_interface_id] : []
  )

  user_data = templatefile("${path.module}/cloud-init.yaml.tftpl", {
    name = each.key
    az   = each.value
    mgmt = each.key == var.ssh_server ? {
      mac           = lower(stackit_network_interface.mgmt.mac)
      ip            = stackit_network_interface.mgmt.ipv4
      network       = stackit_network.wan_network.ipv4_prefix
      prefix_length = split("/", stackit_network.wan_network.ipv4_prefix)[1]
      gateway       = stackit_network.wan_network.ipv4_gateway
    } : null
  })
}

data "stackit_image" "debian" {
  project_id = local.project_id
  image_id   = "87b245b2-5a6e-486d-86ac-947368cb0e8f" // Debian 12 (Bookworm) x86_64
}
