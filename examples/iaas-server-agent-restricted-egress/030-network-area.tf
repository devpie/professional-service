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

resource "stackit_network_area" "this" {
  organization_id = var.stackit_org_id
  name            = var.network_area_name
}

# The regional configuration holds the address ranges of the network area.
# Networks and projects of the area need it, so both depend on it.
resource "stackit_network_area_region" "this" {
  organization_id = var.stackit_org_id
  network_area_id = stackit_network_area.this.network_area_id

  ipv4 = {
    transfer_network    = var.network_area_transfer_network
    network_ranges      = [{ prefix = var.network_area_range }]
    default_nameservers = var.nameservers
  }
}
