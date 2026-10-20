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

# Run Command checks the permission run-command.command.create on the project.
# The role owner on a folder carries no run-command permission, so a service
# account that created the project through that role gets 403 Forbidden. This
# file gives one service account the role run-command.editor on the project:
# an existing one, or one that Terraform creates.

# Created only when run_command_service_account_email is unset. Terraform
# creates no key for it, because the private key would be written to the
# state. The README shows how to create one with the CLI.
resource "stackit_service_account" "run_command" {
  count = var.run_command_service_account_email == null ? 1 : 0

  project_id = local.project_id
  name       = var.run_command_service_account_name
}

locals {
  run_command_service_account_email = (
    var.run_command_service_account_email == null
    ? stackit_service_account.run_command[0].email
    : var.run_command_service_account_email
  )
}

# run-command.editor holds the permissions to read the command templates and
# the agent, and to create, list and read commands. It cannot enable the Run
# Command service.
resource "stackit_authorization_project_role_assignment" "run_command" {
  resource_id = local.project_id
  role        = "run-command.editor"
  subject     = local.run_command_service_account_email
}
