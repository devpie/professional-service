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

variable "stackit_service_account_key_path" {
  description = "Path to the STACKIT service account key file (JSON). Keep this file out of version control."
  type        = string
  default     = "./keys/service-account.json"
}

variable "stackit_organization_id" {
  description = "STACKIT Organization ID (UUID). Found in the portal under Organization > Settings."
  type        = string
}

variable "stackit_folder_id" {
  description = "STACKIT Folder ID (UUID) that will contain the hub project."
  type        = string
}

variable "stackit_region" {
  description = "STACKIT region (e.g. eu01)."
  type        = string
  default     = "eu01"
}

variable "default_zone" {
  description = "Availability zone within the region (e.g. eu01-1)."
  type        = string
  default     = "eu01-1"
}

variable "project_name" {
  description = "Display name of the hub project in STACKIT."
  type        = string
  default     = "hub-project"
}

variable "org_admin" {
  description = "Email address of the STACKIT user who will be set as project owner."
  type        = string
}

variable "mgmt_ip_range" {
  description = "CIDR range allowed to access the firewall management interface (SSH, HTTP, HTTPS). Example: your office or VPN exit IP in /32 or /24 notation."
  type        = string
  default     = ""
}

variable "opnsense_machine_type" {
  description = "Machine type for the OPNsense firewall (e.g. c2i.2, c2i.4)."
  type        = string
  default     = "c2i.2"
}

variable "opnsense_image_path" {
  description = "Path to the OPNsense qcow2 image on the machine that runs Terraform. The file must exist before terraform plan; README.md shows the download command."
  type        = string
  default     = "opnsense.qcow2"
}
