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

variable "project_id" {
  description = "STACKIT project ID."
  type        = string
}

variable "network_id" {
  description = "Network ID (UUID) to attach the server to."
  type        = string
}

variable "name" {
  description = "Server hostname."
  type        = string
}

variable "availability_zone" {
  description = "Availability zone (e.g. eu01-1)."
  type        = string
}

variable "machine_type" {
  description = "Machine type / flavor (e.g. c2i.2, m1a.8d, g2i.16)."
  type        = string
  default     = "c2i.2"
}

variable "image_id" {
  description = "Boot image UUID. Look up the current ID in the STACKIT portal under Compute > Images."
  type        = string
}

variable "disk_size" {
  description = "Boot volume size in GB."
  type        = number
  default     = 50
}

variable "disk_performance_class" {
  description = "Storage performance class (e.g. storage_premium_perf1)."
  type        = string
  default     = "storage_premium_perf1"
}

variable "user_data" {
  description = "Cloud-init user data string."
  type        = string
  default     = ""
}

variable "security_enabled" {
  description = "Enable port security on the network interface."
  type        = bool
  default     = false
}
