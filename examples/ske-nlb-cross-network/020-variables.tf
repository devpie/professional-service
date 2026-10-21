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

variable "stackit_org_id" {
  description = "STACKIT organization ID (used for creating the SNA and projects)"
  type        = string
}

variable "stackit_region" {
  description = "STACKIT region"
  type        = string
  default     = "eu01"
}

variable "stackit_service_account_key_path" {
  description = "Path to the STACKIT service account key JSON file"
  type        = string
  default     = "/keys/sa.json"
}

variable "admin_email" {
  description = "Email address of the project owner"
  type        = string
}

variable "acme_email" {
  description = "Email address for Let's Encrypt ACME account"
  type        = string
}

# ── DNS zone ───────────────────────────────────────────────────────

variable "dns_zone_domain" {
  description = "Fully qualified domain name of the STACKIT DNS zone (e.g. 'xnet-ske.runs.onstackit.cloud')"
  type        = string
  default     = "xnet-ske.runs.onstackit.cloud"
}

# ── SKE cluster ────────────────────────────────────────────────────

variable "cluster_name" {
  description = "Name of the SKE cluster (max 11 chars, alphanumeric + hyphens)"
  type        = string
  default     = "xnet-ske"
}

variable "cluster_kubernetes_version" {
  description = "Minimum Kubernetes version for the cluster"
  type        = string
  default     = "1.34"
}

variable "node_pool_machine_type" {
  description = "Machine type for the SKE node pool"
  type        = string
  default     = "g2i.4"
}

variable "node_pool_minimum" {
  description = "Minimum number of nodes in the SKE node pool"
  type        = number
  default     = 2
}

variable "node_pool_maximum" {
  description = "Maximum number of nodes in the SKE node pool"
  type        = number
  default     = 3
}

variable "node_pool_availability_zones" {
  description = "Availability zones for the SKE node pool"
  type        = list(string)
  default     = ["eu01-1"]
}

variable "node_pool_volume_size" {
  description = "Root volume size in GB for SKE nodes"
  type        = number
  default     = 32
}

variable "node_pool_volume_type" {
  description = "Volume type for SKE nodes"
  type        = string
  default     = "storage_premium_perf6"
}

# ── Nginx application ─────────────────────────────────────────────

variable "nginx_replicas" {
  description = "Number of nginx replicas"
  type        = number
  default     = 1
}

variable "nginx_image" {
  description = "Nginx container image"
  type        = string
  default     = "nginx:1.27"
}

# ── External NLB ───────────────────────────────────────────────────

variable "nlb_name" {
  description = "Name of the external Network Load Balancer"
  type        = string
  default     = "cross-network-nlb"
}

variable "nlb_plan_id" {
  description = "NLB service plan ID"
  type        = string
  default     = "p10"
}

# ── cert-manager Helm chart versions ───────────────────────────────

variable "cert_manager_chart_version" {
  description = "Helm chart version for cert-manager"
  type        = string
  default     = "1.16.2"
}

variable "stackit_cert_manager_webhook_chart_version" {
  description = "Helm chart version for the STACKIT cert-manager webhook"
  type        = string
  default     = "0.4.11"
}
