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
  type        = string
  description = "STACKIT project that holds the SKE cluster"
}

variable "stackit_region" {
  type        = string
  description = "STACKIT region"
  default     = "eu01"
}

variable "stackit_service_account_key_path" {
  type        = string
  description = "Path to the service account key file. Unset falls back to the STACKIT_SERVICE_ACCOUNT_KEY_PATH environment variable, then to that entry in the credentials file ($HOME/.stackit/credentials.json, or STACKIT_CREDENTIALS_PATH)."
  default     = null
}

# Kubernetes 1.36 needs containerd 2.0, which SKE Ubuntu 22.04 nodes lack (SKE
# release note of 2026-08-27). The GPU node pool runs Ubuntu, so the default
# stays on 1.35. SKE expires Kubernetes 1.35 on 2027-02-10.
variable "kubernetes_version_min" {
  type        = string
  description = "Minimum Kubernetes version of the SKE cluster. MAJOR.MINOR selects the newest patch of that minor version. Cluster creation fails once SKE no longer offers the pinned version."
  default     = "1.35"
}
