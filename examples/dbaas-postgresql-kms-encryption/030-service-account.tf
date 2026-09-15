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

# PostgreSQL Flex unwraps the data key through this service account. It needs the
# permission kms.key.version.decrypt, which the role kms.reader does NOT contain.
# Check with: stackit project role list --project-id <id> -o json
resource "stackit_service_account" "postgres_kms" {
  project_id = var.stackit_project_id
  name       = "${var.instance_name}-kms-sa"
}

resource "stackit_authorization_project_role_assignment" "postgres_kms" {
  resource_id = var.stackit_project_id
  role        = "kms.admin"
  subject     = stackit_service_account.postgres_kms.email

  depends_on = [
    stackit_service_account.postgres_kms,
  ]
}
