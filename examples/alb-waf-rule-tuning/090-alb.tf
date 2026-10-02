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

resource "stackit_application_load_balancer" "this" {
  project_id = local.project_id
  region     = var.stackit_region
  name       = "${var.name_prefix}-alb"
  plan_id    = var.alb_plan_id
  labels     = local.labels

  networks = [
    {
      network_id = stackit_network.this.network_id
      role       = "ROLE_LISTENERS_AND_TARGETS"
    }
  ]

  listeners = [
    {
      name     = "https"
      port     = 443
      protocol = "PROTOCOL_HTTPS"

      # Enables the web application firewall for this listener.
      waf_config_name = stackit_alb_waf_configuration.this.name

      https = {
        certificate_config = {
          certificate_ids = [stackit_alb_certificate.this.cert_id]
        }
      }

      http = {
        hosts = [
          {
            host = "*"
            rules = [
              {
                target_pool = "${var.name_prefix}-backends"
                path        = { prefix = "/" }
              },
            ]
          },
        ]
      }
    }
  ]

  target_pools = [
    {
      name        = "${var.name_prefix}-backends"
      target_port = local.backend_port
      targets = [
        for key, nic in stackit_network_interface.backend : {
          display_name = "${var.name_prefix}-backend-${key}"
          ip           = nic.ipv4
        }
      ]
      active_health_check = {
        interval            = "5s"
        interval_jitter     = "1s"
        timeout             = "3s"
        healthy_threshold   = 2
        unhealthy_threshold = 2
        http_health_checks = {
          path      = "/healthz"
          ok_status = ["200"]
        }
      }
    }
  ]

  options = {
    # The load balancer creates and releases its public IP itself.
    ephemeral_address    = true
    private_network_only = false
    access_control = {
      allowed_source_ranges = var.alb_allowed_source_ranges
    }
  }

  # The targets are the addresses of the network interfaces, which exist before
  # the servers do. Wait for the servers so that the load balancer does not
  # start its health checks against ports nobody listens on yet, and for the
  # rule modes so that the listener starts with the tuned rule set.
  depends_on = [
    stackit_server.backend,
    terraform_data.managed_rule_modes,
  ]
}
