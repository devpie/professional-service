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
  jump_public_ip    = stackit_public_ip.jump.ip
  target_private_ip = stackit_network_interface.target.ipv4

  # ProxyJump: the SSH client opens the connection to the target through the
  # jump host. The private key stays on the machine that runs the command.
  ssh_jump   = "ssh -p ${local.jump_ssh_port} ${var.ssh_user}@${local.jump_public_ip}"
  ssh_target = "ssh -J ${var.ssh_user}@${local.jump_public_ip}:${local.jump_ssh_port} ${var.ssh_user}@${local.target_private_ip}"
}

output "project_id" {
  description = "ID of the project this example created."
  value       = local.project_id
}

output "jump_server_id" {
  description = "Server ID of the jump host."
  value       = stackit_server.jump.server_id
}

output "target_server_id" {
  description = "Server ID of the target."
  value       = stackit_server.target.server_id
}

output "jump_public_ip" {
  description = "Public IP of the jump host. sshd listens there on TCP 2222."
  value       = local.jump_public_ip
}

output "target_private_ip" {
  description = "Private IP of the target. Only the jump host reaches it."
  value       = local.target_private_ip
}

output "jump_security_group_id" {
  description = "ID of the jump host's security group."
  value       = stackit_security_group.jump.security_group_id
}

output "target_security_group_id" {
  description = "ID of the target's security group."
  value       = stackit_security_group.target.security_group_id
}

output "run_command_service_account_email" {
  description = "Service account with the role run-command.editor on the project. Send Run Command as this account."
  value       = local.run_command_service_account_email
}

output "ssh_command" {
  description = "Opens a shell on the target through the jump host."
  value       = local.ssh_target
}

output "verify_commands" {
  description = "Commands that check the deployment, one per line. Print them with: terraform output -raw verify_commands"
  value       = <<-EOT
    # Jump host: the only listener outside the loopback addresses is TCP ${local.jump_ssh_port}.
    ${local.ssh_jump} 'ss -Htln'

    # Target: cloud-init finished its first boot without an error. "detail" names DataSourceOpenStackLocal.
    ${local.ssh_target} 'cloud-init status --long'

    # Target, without SSH: the serial console names the data source of the first boot. DataSourceNone means that cloud-init reached no metadata service.
    stackit server log ${stackit_server.target.server_id} --project-id ${local.project_id} --length 5000 | grep -a -E 'No active metadata service found|Datasource DataSource'

    # Target: the unit of the STACKIT Server Agent is active.
    ${local.ssh_target} 'systemctl is-active stackit-server-agent.service'

    # Target: a destination outside the default allow-list, given as an address so the check needs no DNS.
    # curl gets no connection, reports curl error 28 after 10 seconds and then prints 000.
    ${local.ssh_target} 'curl -sS -m 10 -o /dev/null -w "%%{http_code}\n" https://1.1.1.1'

    # Rules of both security groups as the IaaS API reports them.
    stackit security-group rule list --project-id ${local.project_id} --security-group-id ${stackit_security_group.jump.security_group_id}
    stackit security-group rule list --project-id ${local.project_id} --security-group-id ${stackit_security_group.target.security_group_id}

    # Run Command: the platform reaches the Server Agent on the target. The CLI profile run-command holds a key of ${local.run_command_service_account_email}, see "Verify" in the README.
    STACKIT_CLI_PROFILE=run-command stackit server command create --project-id ${local.project_id} --server-id ${stackit_server.target.server_id} --template-name RunShellScript --params script='systemctl is-active stackit-server-agent.service'
  EOT
}
