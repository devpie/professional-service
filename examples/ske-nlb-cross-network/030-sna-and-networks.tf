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
  prefix = "nlb-xnet"
}

# ── STACKIT Network Area (SNA) ─────────────────────────────────────

resource "stackit_network_area" "sna" {
  organization_id = var.stackit_org_id
  name            = "${local.prefix}-sna"
  labels = {
    managed_by = "terraform"
  }
}

resource "stackit_network_area_region" "sna_region" {
  organization_id = var.stackit_org_id
  network_area_id = stackit_network_area.sna.network_area_id
  ipv4 = {
    transfer_network = "172.16.0.0/16"
    network_ranges = [
      { prefix = "10.0.0.0/16" },
    ]
    default_nameservers = ["1.1.1.1", "8.8.8.8"]
  }

  depends_on = [stackit_network_area.sna]
}

# ── Projects ───────────────────────────────────────────────────────

resource "stackit_resourcemanager_project" "ske_project" {
  parent_container_id = var.stackit_org_id
  name                = "${local.prefix}-ske"
  owner_email         = var.admin_email
  labels = {
    "networkArea" = stackit_network_area.sna.network_area_id
    managed_by    = "terraform"
  }
}

resource "stackit_resourcemanager_project" "nlb_project" {
  parent_container_id = var.stackit_org_id
  name                = "${local.prefix}-nlb"
  owner_email         = var.admin_email
  labels = {
    "networkArea" = stackit_network_area.sna.network_area_id
    managed_by    = "terraform"
  }
}

# ── Networks ───────────────────────────────────────────────────────

resource "stackit_network" "ske_network" {
  project_id = stackit_resourcemanager_project.ske_project.project_id
  name       = "${local.prefix}-ske-net"
  routed     = true
  labels = {
    managed_by = "terraform"
  }
}

resource "stackit_network" "nlb_network" {
  project_id = stackit_resourcemanager_project.nlb_project.project_id
  name       = "${local.prefix}-nlb-net"
  routed     = true
  labels = {
    managed_by = "terraform"
  }
}

# ── DNS Zone (for cert-manager DNS-01 validation + app DNS) ────────

resource "stackit_dns_zone" "this" {
  project_id    = stackit_resourcemanager_project.ske_project.project_id
  name          = "${local.prefix}-dns"
  dns_name      = var.dns_zone_domain
  contact_email = var.admin_email
  type          = "primary"
  default_ttl   = 300
}

# ── DNS A record: app.{domain} → external NLB public IP ───────────

resource "stackit_dns_record_set" "app_a_record" {
  project_id = stackit_resourcemanager_project.ske_project.project_id
  zone_id    = stackit_dns_zone.this.zone_id
  name       = "app"
  type       = "A"
  records    = [stackit_public_ip.nlb_ip.ip]
  ttl        = 300
  comment    = "External NLB public IP"
}
