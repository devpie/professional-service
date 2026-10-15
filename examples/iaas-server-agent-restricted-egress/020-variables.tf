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

  validation {
    condition     = can(regex("^[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}$", var.stackit_org_id))
    error_message = "stackit_org_id must be the UUID of an organization, not the placeholder from terraform.tfvars.example."
  }
}

variable "stackit_parent_container_id" {
  description = "Existing folder ID the project is created under, or the organization ID to create it directly under the organization. This example does not create the folder."
  type        = string

  validation {
    condition     = !startswith(var.stackit_parent_container_id, "xxxxxxxx-")
    error_message = "stackit_parent_container_id is still the placeholder from terraform.tfvars.example."
  }
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
  description = "Prefix for the names of the network, the security groups, the network interfaces, the key pair and the two machines. The key pair belongs to the service account that runs Terraform, not to the project. Its name is unique for that account, so a second deployment with the same service account needs another prefix."
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
  description = "One to three IPv4 nameservers of the network. The egress rules with ip_range = \"nameservers\" allow DNS to exactly these addresses."
  type        = list(string)
  default     = ["1.1.1.1", "9.9.9.9"]

  # The IaaS API takes at most three nameservers. Every address becomes part
  # of a for_each key in 060-security-groups.tf, so no address repeats.
  validation {
    condition = (
      length(var.nameservers) >= 1 && length(var.nameservers) <= 3 &&
      length(distinct(var.nameservers)) == length(var.nameservers) &&
      alltrue([for ns in var.nameservers : !strcontains(ns, ":") && can(cidrhost("${ns}/32", 0))])
    )
    error_message = "nameservers needs one to three distinct entries, and every entry must be an IPv4 address without a prefix length."
  }
}

# --- access --------------------------------------------------------------

variable "admin_cidr" {
  description = "IPv4 source range that reaches the jump host on TCP 2222, for example your public IP with a /32 suffix. It must hold the address that STACKIT sees. An internet line with several public IPv4 addresses can show STACKIT a different address from the one an IP lookup service shows."
  type        = string

  validation {
    condition     = !strcontains(var.admin_cidr, ":") && can(cidrhost(var.admin_cidr, 0))
    error_message = "admin_cidr must be an IPv4 range in CIDR notation, for example 198.51.100.10/32."
  }
}

# --- Run Command ---------------------------------------------------------

variable "run_command_service_account_email" {
  description = "Email of an existing service account that sends Run Command to the target. Terraform gives it the role run-command.editor on the project. Unset, Terraform creates a service account in the project and gives the role to that one."
  type        = string
  default     = null

  # The provider rejects a subject with upper-case letters, but only at plan.
  validation {
    condition     = var.run_command_service_account_email == null || can(regex("^[a-z0-9._-]+@[a-z0-9.-]+$", var.run_command_service_account_email))
    error_message = "run_command_service_account_email must be a service account email in lower case, for example name-1234567@sa.stackit.cloud."
  }
}

variable "run_command_service_account_name" {
  description = "Name of the service account Terraform creates when run_command_service_account_email is unset. STACKIT appends a random suffix to form the email."
  type        = string
  default     = "run-command"

  # The provider checks these rules only at plan.
  validation {
    condition     = length(var.run_command_service_account_name) <= 20 && can(regex("^[a-z](-?[a-z0-9]+)*$", var.run_command_service_account_name))
    error_message = "run_command_service_account_name has at most 20 characters, starts with a lower-case letter and holds lower-case letters, digits and single dashes, but no dash at the end."
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
  description = "Outbound allow-list of the target's security group. Each entry becomes one IPv4 egress rule per address range. ip_range takes a CIDR or one of two names: \"nameservers\" stands for every address in var.nameservers, \"stackit\" for every IPv4 range in data.stackit_public_ip_ranges. Leave port_min and port_max unset for a protocol without ports, such as icmp. The default holds the two rules cloud-init, the Server Agent and Run Command need: DHCP and the metadata service."
  type = map(object({
    description = string
    protocol    = string
    port_min    = optional(number)
    port_max    = optional(number)
    ip_range    = string
  }))
  default = {
    dhcp = {
      description = "DHCP: lease and renewal of the IPv4 address of the interface"
      protocol    = "udp"
      port_min    = 67
      port_max    = 67
      ip_range    = "0.0.0.0/0"
    }
    metadata = {
      description = "Metadata service: cloud-init data, Server Agent package, traffic of the Server Agent and the monitoring agent"
      protocol    = "tcp"
      port_min    = 80
      port_max    = 80
      ip_range    = "169.254.169.254/32"
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

# --- machines ------------------------------------------------------------

variable "ssh_public_key" {
  description = "Public SSH key installed on both machines for the default user of the image. Never the private key."
  type        = string
}

variable "ssh_user" {
  description = "User that receives ssh_public_key. STACKIT images create one default user per distribution; on Ubuntu it is \"ubuntu\". The outputs use the name in their SSH commands."
  type        = string
  default     = "ubuntu"
}

variable "image_id" {
  description = "Image UUID of both machines. The cloud-init configuration is written for the public image \"Ubuntu 24.04\" (amd64): it relies on nftables and on sshd socket activation. Look the ID up with: stackit image list --all --project-id <existing project>"
  type        = string

  validation {
    condition     = can(regex("^[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}$", var.image_id))
    error_message = "image_id must be the UUID of an image, not the placeholder from terraform.tfvars.example."
  }
}

variable "availability_zone" {
  description = "Availability zone of both machines."
  type        = string
  default     = "eu01-1"
}

variable "jump_machine_type" {
  description = "Machine type of the jump host. t3i.1 has 1 vCPU and 1 GB RAM."
  type        = string
  default     = "t3i.1"
}

variable "target_machine_type" {
  description = "Machine type of the target. c3i.1 has 1 vCPU and 2 GB RAM."
  type        = string
  default     = "c3i.1"
}

variable "boot_volume_size" {
  description = "Size of each boot volume in GB."
  type        = number
  default     = 20
}
