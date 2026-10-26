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

# TLS termination happens here on the ALB (the NLB only forwards TCP).
# By default a self-signed certificate for the DNS name is used. To use a real
# certificate set tls_cert_file and tls_key_file (PEM, cert incl. chain).
resource "tls_private_key" "alb" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "alb" {
  private_key_pem = tls_private_key.alb.private_key_pem

  subject {
    common_name  = local.fqdn
    organization = "STACKIT Test"
  }
  dns_names = [local.fqdn]

  validity_period_hours = 8760 # 1 year
  early_renewal_hours   = 720  # renew 30 days before expiry on next apply

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

locals {
  use_custom_cert = var.tls_cert_file != "" && var.tls_key_file != ""
  alb_cert_pem    = local.use_custom_cert ? file(var.tls_cert_file) : tls_self_signed_cert.alb.cert_pem
  alb_names       = toset([for i in range(var.alb_count) : "alb${i + 1}"])
}

resource "stackit_alb_certificate" "certificate" {
  project_id  = local.project_id
  name        = "alb-cert-${substr(sha1(local.alb_cert_pem), 0, 8)}" # unique name for create_before_destroy
  private_key = local.use_custom_cert ? file(var.tls_key_file) : tls_private_key.alb.private_key_pem
  public_key  = local.alb_cert_pem

  # The ALB references the certificate: create the new one before deleting the old one
  lifecycle {
    create_before_destroy = true
  }
}

# Application Load Balancers, only reachable privately (the NLB distributes the connections across them).
# Each ALB serves all servers and uses the same certificate.
resource "stackit_application_load_balancer" "alb" {
  for_each   = local.alb_names
  project_id = local.project_id
  region     = var.default_region
  name       = each.key
  plan_id    = var.alb_plan
  listeners = [
    {
      name     = "https"
      port     = 443
      protocol = "PROTOCOL_HTTPS"
      http = {
        hosts = [{
          host = "*"
          rules = [{
            target_pool = "srv-pool"
            path = {
              prefix = "/"
            }
          }]
        }]
      }
      https = {
        certificate_config = {
          certificate_ids = [
            stackit_alb_certificate.certificate.cert_id
          ]
        }
      }
    },
    {
      name     = "http"
      port     = 80
      protocol = "PROTOCOL_HTTP"
      http = {
        hosts = [{
          host = "*"
          rules = [{
            target_pool = "srv-pool"
            path = {
              prefix = "/"
            }
          }]
        }]
      }
    }
  ]
  networks = [
    {
      network_id = stackit_network.lan_network1.network_id
      role       = "ROLE_LISTENERS_AND_TARGETS"
    }
  ]
  options = {
    # Not changeable after creation.
    ephemeral_address    = false
    private_network_only = true
  }
  target_pools = [
    {
      name        = "srv-pool"
      target_port = 80
      active_health_check = {
        interval            = "5s"
        interval_jitter     = "0.500s"
        timeout             = "2s"
        healthy_threshold   = 2
        unhealthy_threshold = 3
        http_health_checks = {
          ok_status = ["200"]
          path      = "/"
        }
      }
      targets = [
        for name, server in stackit_server.srv : {
          display_name = name
          ip           = stackit_network_interface.srv[name].ipv4
        }
      ]
    }
  ]
  # Access from the ALBs to the servers is granted by our own security group (040-security-group.tf).
  # Not changeable after creation.
  disable_target_security_group_assignment = true
}
