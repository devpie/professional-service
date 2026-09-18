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

# The encryption block is only accepted on create. Changing any of its fields forces
# a replacement of the instance, which deletes the instance and its backups.
resource "stackit_postgresflex_instance" "this" {
  project_id      = var.stackit_project_id
  name            = var.instance_name
  version         = var.postgres_version
  flavor_id       = var.flavor_id
  backup_schedule = var.backup_schedule
  retention_days  = var.retention_days

  storage = {
    class = var.storage_class
    size  = var.storage_size
  }

  network = {
    acl = var.acl
  }

  encryption = {
    kek_keyring_id  = stackit_kms_keyring.postgres.keyring_id
    kek_key_id      = stackit_kms_key.postgres.key_id
    kek_key_version = var.kek_key_version
    service_account = stackit_service_account.postgres_kms.email
  }

  # A replacement is data loss, not a configuration change.
  # comment this, if you really want to replace or destroy this instance:
  lifecycle {
    prevent_destroy = true
  }

  depends_on = [
    stackit_authorization_project_role_assignment.postgres_kms,
  ]
}

resource "stackit_postgresflex_user" "app" {
  project_id  = var.stackit_project_id
  instance_id = stackit_postgresflex_instance.this.instance_id
  username    = "app"
  roles       = ["login", "createdb"]
}

resource "stackit_postgresflex_database" "app" {
  project_id  = var.stackit_project_id
  instance_id = stackit_postgresflex_instance.this.instance_id
  name        = "app"
  owner       = stackit_postgresflex_user.app.username
}
