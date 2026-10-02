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

terraform {
  # The S3 backend settings in backend.conf.example (endpoints,
  # skip_requesting_account_id, skip_s3_checksum) need Terraform 1.6.3 or later.
  required_version = ">= 1.6.3"

  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = ">= 0.117.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.4.0"
    }
  }
}

provider "stackit" {
  default_region           = var.region
  service_account_key_path = var.service_account_key_path
}
