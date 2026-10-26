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

// Routing table for the networks of the network area (experiment "routing-tables")
resource "stackit_routing_table" "rt" {
  organization_id = var.organization_id
  network_area_id = stackit_network_area.sna.network_area_id
  region          = var.default_region
  name            = "nlbalb-rt"
  system_routes   = true // keep project-to-project routes
  dynamic_routes  = true

  depends_on = [stackit_network_area_region.sna1]
}

// No default route needed: outbound internet is provided by the internal STACKIT router (SNAT).
// Add custom routes with stackit_routing_table_route and assign the table via routing_table_id on a network.
