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

# Security group for the servers.
# The ALBs have disable_target_security_group_assignment = true, so access from the ALBs is allowed here.
resource "stackit_security_group" "srv" {
  project_id  = local.project_id
  name        = "srv"
  description = "nginx servers behind the ALBs"
  stateful    = true
}

# HTTP from the ALBs only (one rule per ALB)
resource "stackit_security_group_rule" "srv_http_from_alb" {
  for_each                 = stackit_application_load_balancer.alb
  project_id               = local.project_id
  security_group_id        = stackit_security_group.srv.security_group_id
  direction                = "ingress"
  remote_security_group_id = each.value.load_balancer_security_group.id
  protocol = {
    name = "tcp"
  }
  port_range = {
    min = 80
    max = 80
  }
}

# SSH between the servers (jump from var.ssh_server to the others)
resource "stackit_security_group_rule" "srv_ssh_internal" {
  project_id               = local.project_id
  security_group_id        = stackit_security_group.srv.security_group_id
  direction                = "ingress"
  remote_security_group_id = stackit_security_group.srv.security_group_id
  protocol = {
    name = "tcp"
  }
  port_range = {
    min = 22
    max = 22
  }
}

# Outbound internet for package installation
resource "stackit_security_group_rule" "srv_egress_tcp" {
  project_id        = local.project_id
  security_group_id = stackit_security_group.srv.security_group_id
  direction         = "egress"
  ip_range          = "0.0.0.0/0"
  protocol = {
    name = "tcp"
  }
}

resource "stackit_security_group_rule" "srv_egress_dns" {
  project_id        = local.project_id
  security_group_id = stackit_security_group.srv.security_group_id
  direction         = "egress"
  ip_range          = "0.0.0.0/0"
  protocol = {
    name = "udp"
  }
  port_range = {
    min = 53
    max = 53
  }
}

# Security group for the management interface: SSH from var.ssh_allowed_cidr
resource "stackit_security_group" "ssh" {
  project_id  = local.project_id
  name        = "ssh"
  description = "SSH access via public IP"
  stateful    = true
}

resource "stackit_security_group_rule" "ssh_ingress" {
  project_id        = local.project_id
  security_group_id = stackit_security_group.ssh.security_group_id
  direction         = "ingress"
  ip_range          = var.ssh_allowed_cidr
  protocol = {
    name = "tcp"
  }
  port_range = {
    min = 22
    max = 22
  }
}
