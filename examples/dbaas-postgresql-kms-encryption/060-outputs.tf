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

output "instance_id" {
  description = "ID of the PostgreSQL Flex instance"
  value       = stackit_postgresflex_instance.this.instance_id
}

output "instance_host" {
  description = "Endpoint of the instance. A clone gets its own endpoint."
  value       = try(stackit_postgresflex_instance.this.connection_info.write.host, null)
}

output "keyring_id" {
  description = "ID of the KMS keyring"
  value       = stackit_kms_keyring.postgres.keyring_id
}

output "key_id" {
  description = "ID of the key encryption key"
  value       = stackit_kms_key.postgres.key_id
}

output "kek_key_version" {
  description = "Key version the instance is pinned to. Record it: it must stay active for the whole lifetime of the instance and its backups."
  value       = var.kek_key_version
}

output "kms_service_account" {
  description = "Service account PostgreSQL Flex uses to unwrap the key"
  value       = stackit_service_account.postgres_kms.email
}

output "database_user" {
  description = "Name of the created database user"
  value       = stackit_postgresflex_user.app.username
}

output "database_password" {
  description = "Password of the created database user"
  value       = stackit_postgresflex_user.app.password
  sensitive   = true
}
