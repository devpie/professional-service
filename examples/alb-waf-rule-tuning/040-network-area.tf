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

# A STACKIT Network Area (SNA) is created on organization level. It owns the
# address range that the networks of all its projects share.
resource "stackit_network_area" "this" {
  organization_id = var.stackit_org_id
  name            = "${var.name_prefix}-sna"
  labels          = local.labels
}

resource "stackit_network_area_region" "this" {
  organization_id = var.stackit_org_id
  network_area_id = stackit_network_area.this.network_area_id

  ipv4 = {
    transfer_network    = var.sna_transfer_network
    network_ranges      = [{ prefix = var.sna_network_range }]
    default_nameservers = var.nameservers
  }
}

# A project joins a network area through the networkArea label, and only at
# creation. An existing project cannot be moved into an area.
resource "stackit_resourcemanager_project" "this" {
  parent_container_id = var.stackit_parent_container_id
  name                = var.project_name
  owner_email         = var.stackit_admin_email

  labels = {
    "networkArea" = stackit_network_area.this.network_area_id
  }

  # The regional configuration of the area cannot be deleted while a project
  # belongs to the area. The dependency makes a destroy remove the project
  # first.
  depends_on = [stackit_network_area_region.this]
}
