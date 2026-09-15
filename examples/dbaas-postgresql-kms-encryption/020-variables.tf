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

#
# Custom User Settings
#

# No default on purpose: Terraform asks for this value if you forget it.
variable "stackit_project_id" {
  type        = string
  description = "STACKIT Project ID"
}

variable "stackit_region" {
  type        = string
  description = "STACKIT region"
  default     = "eu01"
}

variable "stackit_service_account_key_path" {
  type        = string
  description = "Path to the service account key file used by Terraform. Keep it out of version control."
  default     = "./keys/stackit-sa.json"
}

variable "instance_name" {
  type        = string
  description = "Name of the PostgreSQL Flex instance"
  default     = "pg-kms-example"
}

# No default on purpose: a wrong ACL locks you out of your own database.
variable "acl" {
  type        = list(string)
  description = "Networks allowed to reach the instance, e.g. [\"203.0.113.10/32\"]. Never 0.0.0.0/0 in production."
}

variable "flavor_id" {
  type        = string
  description = "Flavor of the instance. List them with: stackit postgresflex flavor list"
  default     = "2.4"
}

variable "storage_class" {
  type        = string
  description = "Storage class of the instance"
  default     = "premium-perf2-stackit"
}

variable "storage_size" {
  type        = number
  description = "Storage size in GB"
  default     = 10
}

variable "postgres_version" {
  type        = string
  description = "PostgreSQL major version"
  default     = "17"
}

variable "backup_schedule" {
  type        = string
  description = "Cron expression in UTC. One run per day, the API does not allow a manual backup."
  default     = "0 2 * * *"
}

variable "retention_days" {
  type        = number
  description = "How long backups are kept. Allowed range is 32 to 90 days."
  default     = 32
}

variable "kek_key_version" {
  type        = string
  description = "Key version used for the instance. It is fixed for the lifetime of the instance; changing it replaces the instance and destroys its data."
  default     = "1"
}
