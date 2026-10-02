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

locals {
  labels = {
    example    = "alb-waf-rule-tuning"
    managed-by = "terraform"
  }

  project_id = stackit_resourcemanager_project.this.project_id

  # One backend VM per availability zone, keyed by a two-digit index.
  backends = { for idx, az in var.availability_zones : format("%02d", idx + 1) => az }

  backend_port = 8080
}
