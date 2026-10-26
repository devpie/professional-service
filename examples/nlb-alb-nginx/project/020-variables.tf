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

# -- variables (values are passed in from the root module)
variable "organization_id" {
  type        = string
  description = "STACKIT organization ID"
}

variable "default_region" {
  type        = string
  description = "Region for the network area and routing table"
}

variable "projects" {
  type = map(object({
    name        = string
    owner_email = optional(string)
  }))
  description = "Projects to create in the network area: key => name and optional owner e-mail"
}

variable "owner_email" {
  type        = string
  description = "Default owner e-mail for all projects without own owner_email"
}

variable "project_deletion_wait" {
  type        = string
  description = "Wait time on destroy between deleting the projects and the network area region"
  default     = "180s"
}
