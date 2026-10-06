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
  description = "Path to the service account key file. Unset falls back to the STACKIT_SERVICE_ACCOUNT_KEY_PATH environment variable, then to that entry in the credentials file ($HOME/.stackit/credentials.json, or STACKIT_CREDENTIALS_PATH)."
  type        = string
  default     = null
}

variable "stackit_parent_container_id" {
  description = "Container ID of the organization or folder the project is created in."
  type        = string
}

variable "stackit_project_name" {
  description = "Display name of the project this stage creates."
  type        = string
  default     = "00-bootstrap"
}

variable "stackit_admin_email" {
  description = "Email address of the STACKIT user who will be set as project owner."
  type        = string
}

variable "stackit_region" {
  description = "STACKIT region (e.g. eu01)."
  type        = string
  default     = "eu01"
}
