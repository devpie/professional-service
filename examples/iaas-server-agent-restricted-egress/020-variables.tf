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
  description = "The STACKIT organization ID in which the network area is created."
  type        = string
}

variable "stackit_parent_container_id" {
  description = "Existing folder ID the project is created under, or the organization ID to create it directly under the organization. This example does not create the folder."
  type        = string
}

variable "stackit_admin_email" {
  description = "An existing STACKIT user that becomes owner of the created project. A non-existent address fails with 409 \"subject is not found\"."
  type        = string
}

variable "stackit_region" {
  description = "The STACKIT region."
  type        = string
  default     = "eu01"
}

variable "stackit_service_account_key_path" {
  description = "Path to the service account key file. Unset falls back to the STACKIT_SERVICE_ACCOUNT_KEY_PATH environment variable, then to that entry in the credentials file ($HOME/.stackit/credentials.json, or STACKIT_CREDENTIALS_PATH)."
  type        = string
  default     = null
}

# --- naming --------------------------------------------------------------

variable "project_name" {
  description = "Display name of the project this example creates."
  type        = string
  default     = "server-agent-egress"
}

variable "network_area_name" {
  description = "Name of the STACKIT Network Area this example creates."
  type        = string
  default     = "server-agent-egress"
}

variable "name_prefix" {
  description = "Prefix for the names of the network, the security groups, the network interfaces, the key pair and the two machines."
  type        = string
  default     = "agent-egress"
}

# --- addressing ----------------------------------------------------------

variable "network_area_range" {
  description = "IPv4 range of the network area."
  type        = string
  default     = "10.80.0.0/16"
}

variable "network_area_transfer_network" {
  description = "Transfer network of the network area. It must not overlap with network_area_range."
  type        = string
  default     = "172.30.0.0/16"
}

variable "network_prefix" {
  description = "Prefix of the network that holds both machines. It must sit inside network_area_range."
  type        = string
  default     = "10.80.1.0/24"
}

variable "nameservers" {
  description = "IPv4 nameservers of the network. The egress rules with ip_range = \"nameservers\" allow DNS to exactly these addresses."
  type        = list(string)
  default     = ["1.1.1.1", "9.9.9.9"]

  validation {
    condition     = length(var.nameservers) > 0 && alltrue([for ns in var.nameservers : !strcontains(ns, ":") && can(cidrhost("${ns}/32", 0))])
    error_message = "nameservers needs at least one entry, and every entry must be an IPv4 address without a prefix length."
  }
}
