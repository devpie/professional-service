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
  # sshd on the jump host listens on this port. The security group rule, the
  # sshd configuration and the outputs read it from here.
  jump_ssh_port = 2222
}

# --- jump host -----------------------------------------------------------
#
# A security group only allows. Terraform adds one ingress rule to the group:
# new connections on TCP 2222 from admin_cidr. The group is stateful: answers
# to connections the jump host opened itself pass without a rule.
resource "stackit_security_group" "jump" {
  project_id  = local.project_id
  name        = "${var.name_prefix}-jump"
  description = "Jump host: inbound SSH on TCP ${local.jump_ssh_port} from the admin range only"
  stateful    = true
}

resource "stackit_security_group_rule" "jump_ssh" {
  project_id        = local.project_id
  security_group_id = stackit_security_group.jump.security_group_id
  description       = "SSH from the admin range to the port sshd listens on"
  direction         = "ingress"
  ether_type        = "IPv4"
  protocol          = { name = "tcp" }
  port_range        = { min = local.jump_ssh_port, max = local.jump_ssh_port }
  ip_range          = var.admin_cidr
}

# The jump host is not the subject of the egress test. Its group keeps the two
# default egress rules that STACKIT adds to every new security group.

# --- target --------------------------------------------------------------
#
# The target has no public IP. The ingress rule Terraform adds names the jump
# host's security group as the source, so SSH reaches the target from the
# jump host and from nowhere else.
resource "stackit_security_group" "target" {
  project_id  = local.project_id
  name        = "${var.name_prefix}-target"
  description = "Target: inbound SSH from the jump host's group, outbound traffic from an allow-list"
  stateful    = true

  # A deleted default egress rule does not come back. A change of egress_mode
  # therefore creates a new group, which starts with its two default rules.
  lifecycle {
    replace_triggered_by = [terraform_data.egress_mode]
  }
}

resource "stackit_security_group_rule" "target_ssh" {
  project_id               = local.project_id
  security_group_id        = stackit_security_group.target.security_group_id
  description              = "SSH from members of the jump host's security group"
  direction                = "ingress"
  ether_type               = "IPv4"
  protocol                 = { name = "tcp" }
  port_range               = { min = 22, max = 22 }
  remote_security_group_id = stackit_security_group.jump.security_group_id
}

# --- outbound allow-list of the target -----------------------------------

# The public IPv4 and IPv6 ranges STACKIT uses. The data source needs no
# project, so Terraform reads it while planning.
data "stackit_public_ip_ranges" "this" {}

locals {
  # The destinations an egress rule can name instead of a CIDR. The rules are
  # IPv4 rules, so IPv6 ranges are left out.
  egress_named_destinations = {
    nameservers = tolist([for nameserver in var.nameservers : "${nameserver}/32"])
    stackit     = tolist([for cidr in data.stackit_public_ip_ranges.this.cidr_list : cidr if !strcontains(cidr, ":")])
  }

  # A security group rule takes one address range. An entry of egress_rules
  # that names a group of destinations becomes one rule per range.
  target_egress_rules = merge([
    for name, rule in var.egress_rules : {
      for cidr in lookup(local.egress_named_destinations, rule.ip_range, tolist([rule.ip_range])) :
      (contains(keys(local.egress_named_destinations), rule.ip_range) ? "${name}-${cidr}" : name) => merge(rule, { ip_range = cidr })
    }
  ]...)
}

resource "stackit_security_group_rule" "target_egress" {
  for_each = local.target_egress_rules

  project_id        = local.project_id
  security_group_id = stackit_security_group.target.security_group_id
  description       = each.value.description
  direction         = "egress"
  ether_type        = "IPv4"
  protocol          = { name = each.value.protocol }
  port_range        = each.value.port_min == null ? null : { min = each.value.port_min, max = each.value.port_max }
  ip_range          = each.value.ip_range
}
