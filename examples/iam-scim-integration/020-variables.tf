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

variable "stackit_project_id" {
  type = string
}

variable "stackit_region" {
  type    = string
  default = "eu01"
}

variable "stackit_service_account_key_path" {
  type        = string
  description = "Path to the service account key file. Unset falls back to the STACKIT_SERVICE_ACCOUNT_KEY_PATH environment variable, then to that entry in the credentials file ($HOME/.stackit/credentials.json, or STACKIT_CREDENTIALS_PATH)."
  default     = null
}

variable "acme_email" {
  description = "The email address used for ACME registration."
  type        = string
}

variable "authentik_scim_long_lived_token" {
  description = "The SCIM synchronization token provided by the IDP team. This configuration uses a long-lived static token due to Authentik Community Edition limitations. For production environments, dynamically generated, short-lived tokens are highly recommended."
  type        = string
}

variable "authentik_number_of_users" {
  description = "The number of test users to generate"
  type        = number
}

variable "authentik_default_user_password" {
  description = "The default password assigned to all created test users"
  type        = string
  sensitive   = true
}
