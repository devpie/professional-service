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

# ── Public IP for external NLB ─────────────────────────────────────

resource "stackit_public_ip" "nlb_ip" {
  project_id = stackit_resourcemanager_project.nlb_project.project_id
  labels = {
    managed_by = "terraform"
  }

  lifecycle {
    ignore_changes = [network_interface_id]
  }
}

# ── External NLB (TLS passthrough → internal LB) ───────────────────
# The target IP is taken from the internal LoadBalancer service's
# ingress status. Terraform resolves this dependency automatically.

resource "stackit_loadbalancer" "nlb" {
  project_id                        = stackit_resourcemanager_project.nlb_project.project_id
  name                              = var.nlb_name
  plan_id                           = var.nlb_plan_id
  external_address                  = stackit_public_ip.nlb_ip.ip
  disable_security_group_assignment = true

  networks = [
    {
      network_id = stackit_network.nlb_network.network_id
      role       = "ROLE_LISTENERS_AND_TARGETS"
    },
  ]

  listeners = [
    {
      display_name = "tls-passthrough-443"
      port         = 443
      protocol     = "PROTOCOL_TLS_PASSTHROUGH"
      target_pool  = "internal-lb"
    },
  ]

  target_pools = [
    {
      name        = "internal-lb"
      target_port = 443
      targets = [
        {
          display_name = "internal-lb"
          ip           = kubernetes_service_v1.nginx_internal_lb_tls.status[0].load_balancer[0].ingress[0].ip
        },
      ]
      active_health_check = {
        interval            = "3s"
        interval_jitter     = "1s"
        timeout             = "3s"
        healthy_threshold   = 3
        unhealthy_threshold = 3
      }
    },
  ]

  depends_on = [kubernetes_service_v1.nginx_internal_lb_tls]
}
