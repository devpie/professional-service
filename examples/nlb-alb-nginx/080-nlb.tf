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

# Public IP for the NLB
resource "stackit_public_ip" "nlb" {
  project_id = local.project_id
  lifecycle {
    ignore_changes = [network_interface_id]
  }
}

# Network Load Balancer (Layer 4): distributes TCP 80/443 connections unchanged across all ALBs.
# It sits in front to get beyond the connection limit of a single ALB (plan p10: 10,000).
resource "stackit_loadbalancer" "nlb" {
  project_id       = local.project_id
  region           = var.default_region
  name             = "nlb"
  plan_id          = var.nlb_plan
  external_address = stackit_public_ip.nlb.ip
  listeners = [
    {
      display_name = "https"
      port         = 443
      protocol     = "PROTOCOL_TCP"
      target_pool  = "alb-https"
    },
    {
      display_name = "http"
      port         = 80
      protocol     = "PROTOCOL_TCP"
      target_pool  = "alb-http"
    }
  ]
  target_pools = [
    {
      name        = "alb-https"
      target_port = 443
      targets = [
        for name, alb in stackit_application_load_balancer.alb : {
          display_name = name
          ip           = alb.private_address
        }
      ]
    },
    {
      name        = "alb-http"
      target_port = 80
      targets = [
        for name, alb in stackit_application_load_balancer.alb : {
          display_name = name
          ip           = alb.private_address
        }
      ]
    }
  ]
  networks = [
    {
      network_id = stackit_network.lan_network1.network_id
      role       = "ROLE_LISTENERS_AND_TARGETS"
    }
  ]
  # The targets are ALBs (managed by STACKIT), not VMs: no security group assignment possible
  disable_security_group_assignment = true
  options = {
    private_network_only = false
  }
}
