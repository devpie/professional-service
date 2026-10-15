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

output "egress_mode" {
  description = "Rule set the target booted with: \"restricted\" or \"open\"."
  value       = var.egress_mode
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

output "ssh_command" {
  description = "Opens a shell on the target through the jump host."
  value       = local.ssh_target
}

output "verify_commands" {
  description = "Commands that check the deployment, one per line. Print them with: terraform output -raw verify_commands"
  value       = <<-EOT
    # Jump host: the only listener outside the loopback addresses is TCP ${local.jump_ssh_port}.
    ${local.ssh_jump} 'ss -Htln'

    # Target: cloud-init finished its first boot without an error.
    ${local.ssh_target} 'cloud-init status --long'

    # Target: the unit of the STACKIT Server Agent is active.
    ${local.ssh_target} 'systemctl is-active stackit-server-agent.service'

    # Target: DNS and HTTPS reach the endpoint of the Server Agent signature. Prints the HTTP status.
    ${local.ssh_target} 'curl -sS -o /dev/null -w "%%{http_code}\n" https://stackit-server-agent.object.storage.${var.stackit_region}.onstackit.cloud/stackit-server-agent.gpg'

    # Target: a destination outside the default allow-list. "restricted": curl gets no connection and prints 000. "open": curl prints the HTTP status.
    # curl error 28 is the timeout of a dropped connection. Error 6 means the name did not resolve; the check is then void.
    ${local.ssh_target} 'curl -sS -m 10 -o /dev/null -w "%%{http_code}\n" https://example.com'

    # Target: destinations of the outbound connections the probe logged, over all boots.
    ${local.ssh_target} 'sudo egress-probe-report'

    # Rules of both security groups as the IaaS API reports them.
    stackit security-group rule list --project-id ${local.project_id} --security-group-id ${stackit_security_group.jump.security_group_id}
    stackit security-group rule list --project-id ${local.project_id} --security-group-id ${stackit_security_group.target.security_group_id}

    # Run Command: the platform reaches the Server Agent on the target.
    stackit server command create --project-id ${local.project_id} --server-id ${stackit_server.target.server_id} --template-name RunShellScript --params script='systemctl is-active stackit-server-agent.service'
  EOT
}
