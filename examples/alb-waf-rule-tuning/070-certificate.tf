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

# Self-signed certificate for the HTTPS listener. The requests in the README
# address the load balancer by its IP and skip certificate verification.
resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "this" {
  private_key_pem = tls_private_key.this.private_key_pem

  subject {
    common_name  = "${var.name_prefix}.example.internal"
    organization = "STACKIT Example"
  }

  dns_names             = ["${var.name_prefix}.example.internal"]
  validity_period_hours = 8760

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "stackit_alb_certificate" "this" {
  project_id  = local.project_id
  region      = var.stackit_region
  name        = "${var.name_prefix}-cert"
  private_key = tls_private_key.this.private_key_pem
  public_key  = tls_self_signed_cert.this.cert_pem
}
