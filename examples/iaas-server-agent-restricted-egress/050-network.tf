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

# One network holds the jump host and the target. The two machines are
# separated by their security groups, not by the network.
resource "stackit_network" "this" {
  project_id       = local.project_id
  name             = var.name_prefix
  ipv4_prefix      = var.network_prefix
  ipv4_nameservers = var.nameservers

  depends_on = [stackit_network_area_region.this]
}
