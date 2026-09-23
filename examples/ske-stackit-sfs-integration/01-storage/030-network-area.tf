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

# The network area owns the address space. Every project that carries the
# networkArea label below draws its networks from this range.
resource "stackit_network_area" "sfs" {
  organization_id = var.stackit_org_id
  name            = var.sna_name
  labels = {
    "preview/routingtables" = "true"
  }
}

# File Storage carves one /28 and four /29 out of this range. No prefix length
# is set: the provider already sends 24 to 29, which covers that.
resource "stackit_network_area_region" "sfs" {
  organization_id = var.stackit_org_id
  network_area_id = stackit_network_area.sfs.network_area_id
  ipv4 = {
    transfer_network = var.sna_transfer_network
    network_ranges = [
      {
        prefix = var.sna_network_range
      }
    ]
  }
}
