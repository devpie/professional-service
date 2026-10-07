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
