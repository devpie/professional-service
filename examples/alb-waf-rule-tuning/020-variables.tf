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
    condition     = can(regex("^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$", var.stackit_org_id))
    error_message = "The stackit_org_id must be a valid UUID."
  }
}

variable "stackit_parent_container_id" {
  description = "Existing folder ID the project is created under, or the organization ID to create it directly under the organization. This example does not create the folder."
  type        = string
}

variable "stackit_admin_email" {
  description = "An existing STACKIT user that becomes owner of the created project. A non-existent address fails with 409 'subject is not found'."
  type        = string
}

variable "stackit_region" {
  description = "The STACKIT region to deploy resources into."
  type        = string
  default     = "eu01"
}

variable "stackit_service_account_key_path" {
  description = "Path to the STACKIT service account key JSON file. The service account creates the network area in the organization and the project under stackit_parent_container_id, and its access token changes the rule modes of the managed rule set."
  type        = string
}

# --- naming --------------------------------------------------------------

variable "project_name" {
  description = "Display name of the project that is created inside the network area."
  type        = string
  default     = "alb-waf-rule-tuning"
}

variable "name_prefix" {
  description = "Prefix applied to the names of all resources. Lowercase letters, digits and hyphens only."
  type        = string
  default     = "alb-waf"

  validation {
    condition     = can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", var.name_prefix)) && length(var.name_prefix) <= 20
    error_message = "The name_prefix must be 1-20 characters of lowercase letters, digits and single hyphens, starting and ending with a letter or digit."
  }
}

# --- addressing ----------------------------------------------------------

variable "sna_network_range" {
  description = "IPv4 range of the STACKIT Network Area. Every network of a project in the area takes its prefix from this range."
  type        = string
  default     = "10.60.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.sna_network_range))
    error_message = "The sna_network_range must be a valid IPv4 CIDR, e.g. 10.60.0.0/16."
  }
}

variable "sna_transfer_network" {
  description = "IPv4 transfer network of the STACKIT Network Area. It must not overlap with sna_network_range."
  type        = string
  default     = "172.16.60.0/24"

  validation {
    condition     = can(cidrnetmask(var.sna_transfer_network))
    error_message = "The sna_transfer_network must be a valid IPv4 CIDR, e.g. 172.16.60.0/24."
  }
}

variable "network_cidr" {
  description = "IPv4 prefix of the network that hosts the backends and the load balancer. It must lie inside sna_network_range."
  type        = string
  default     = "10.60.1.0/24"

  validation {
    condition     = can(cidrnetmask(var.network_cidr))
    error_message = "The network_cidr must be a valid IPv4 CIDR, e.g. 10.60.1.0/24."
  }
}

variable "nameservers" {
  description = "DNS servers of the network area and of the network."
  type        = list(string)
  default     = ["1.1.1.1", "9.9.9.9"]
}

# --- backends ------------------------------------------------------------

variable "availability_zones" {
  description = "Availability zones for the backend VMs. One VM is created per zone."
  type        = list(string)
  default     = ["eu01-1", "eu01-2"]

  validation {
    condition     = length(var.availability_zones) >= 1 && length(var.availability_zones) <= 3
    error_message = "Provide between one and three availability zones."
  }
}

variable "machine_type" {
  description = "Machine type of the backend VMs."
  type        = string
  default     = "c2i.1"
}

variable "image_id" {
  description = "Image UUID of the boot image for the backend VMs. The default is Debian 13 in eu01. The image must ship python3."
  type        = string
  default     = "1525a2a0-474c-4ece-a840-aca260348a9f"
}

variable "boot_volume_size_gb" {
  description = "Boot volume size of each backend VM in GB."
  type        = number
  default     = 20
}

# --- load balancer -------------------------------------------------------

variable "alb_plan_id" {
  description = "Service plan of the Application Load Balancer. List the plans of your region with `stackit beta alb plans`."
  type        = string
  default     = "p10"
}

variable "alb_allowed_source_ranges" {
  description = "Source CIDRs that may reach the load balancer listener."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# --- web application firewall --------------------------------------------

variable "managed_rule_modes" {
  description = "Mode per rule of the managed rule set, keyed by rule ID. MODE_DISABLED skips the rule, MODE_LOG_ONLY logs a match and lets the request pass, MODE_ENABLED applies the rule. Rules that are not listed are in MODE_ENABLED. The README shows how to list every rule ID of the rule set."
  type        = map(string)
  default = {
    # Scanner detection by User-Agent: disabled.
    "913100" = "MODE_DISABLED"
    # SQL injection detection via libinjection: logged, not blocked.
    "942100" = "MODE_LOG_ONLY"
  }

  validation {
    condition     = alltrue([for mode in values(var.managed_rule_modes) : contains(["MODE_ENABLED", "MODE_LOG_ONLY", "MODE_DISABLED"], mode)])
    error_message = "Every mode in managed_rule_modes must be MODE_ENABLED, MODE_LOG_ONLY or MODE_DISABLED."
  }
}
