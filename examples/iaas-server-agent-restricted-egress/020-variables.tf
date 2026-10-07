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

# --- access --------------------------------------------------------------

variable "admin_cidr" {
  description = "IPv4 source range that reaches the jump host on TCP 2222, for example your public IP with a /32 suffix."
  type        = string

  validation {
    condition     = !strcontains(var.admin_cidr, ":") && can(cidrhost(var.admin_cidr, 0))
    error_message = "admin_cidr must be an IPv4 range in CIDR notation, for example 198.51.100.10/32."
  }
}

# --- outbound traffic of the target --------------------------------------

variable "egress_mode" {
  description = "\"restricted\" removes the two default egress rules from the target's security group, so only egress_rules allows outbound traffic. \"open\" keeps the default rules, so all outbound traffic passes; use it to record what the machine contacts. A change replaces the target's security group, network interface and server."
  type        = string
  default     = "restricted"

  validation {
    condition     = contains(["restricted", "open"], var.egress_mode)
    error_message = "egress_mode must be \"restricted\" or \"open\"."
  }
}

variable "egress_rules" {
  description = "Outbound allow-list of the target's security group. Each entry becomes one IPv4 egress rule. ip_range takes a CIDR or one of two names: \"nameservers\" stands for every address in var.nameservers, \"stackit\" for every IPv4 range in data.stackit_public_ip_ranges. Leave port_min and port_max unset for a protocol without ports, such as icmp. The default holds the destinations the STACKIT documentation names."
  type = map(object({
    description = string
    protocol    = string
    port_min    = optional(number)
    port_max    = optional(number)
    ip_range    = string
  }))
  default = {
    metadata = {
      description = "Metadata service: cloud-init reads user data, metadata and vendor data; download of the Server Agent package"
      protocol    = "tcp"
      port_min    = 80
      port_max    = 80
      ip_range    = "169.254.169.254/32"
    }
    dns-udp = {
      description = "DNS: resolves the host names of the HTTPS destinations"
      protocol    = "udp"
      port_min    = 53
      port_max    = 53
      ip_range    = "nameservers"
    }
    dns-tcp = {
      description = "DNS over TCP: answers that do not fit into a UDP datagram"
      protocol    = "tcp"
      port_min    = 53
      port_max    = 53
      ip_range    = "nameservers"
    }
    https-stackit = {
      description = "HTTPS to the STACKIT public IP ranges: signature check of the Server Agent package on Object Storage"
      protocol    = "tcp"
      port_min    = 443
      port_max    = 443
      ip_range    = "stackit"
    }
  }

  validation {
    condition = alltrue([
      for rule in values(var.egress_rules) :
      contains(["nameservers", "stackit"], rule.ip_range) || (!strcontains(rule.ip_range, ":") && can(cidrhost(rule.ip_range, 0)))
    ])
    error_message = "ip_range of every egress rule must be an IPv4 range in CIDR notation, \"nameservers\" or \"stackit\"."
  }

  validation {
    condition = alltrue([
      for rule in values(var.egress_rules) :
      length(rule.description) >= 1 && length(rule.description) <= 127
    ])
    error_message = "description of every egress rule must have 1 to 127 characters. The STACKIT provider rejects longer rule descriptions."
  }

  validation {
    condition = alltrue([
      for rule in values(var.egress_rules) :
      (rule.port_min == null) == (rule.port_max == null)
    ])
    error_message = "Every egress rule sets both port_min and port_max, or neither."
  }
}
