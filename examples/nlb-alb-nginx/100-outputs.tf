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

output "url" {
  value = "https://${local.fqdn}"
}

output "fqdn" {
  value = local.fqdn
}

output "project_id" {
  value = local.project_id
}

output "nlb_public_ip" {
  value = stackit_public_ip.nlb.ip
}

output "ssh" {
  value = {
    (var.ssh_server) = "ssh debian@${stackit_public_ip.ssh.ip}"
    other_servers = {
      for name, nic in stackit_network_interface.srv :
      name => "ssh -J debian@${stackit_public_ip.ssh.ip} debian@${nic.ipv4}" if name != var.ssh_server
    }
  }
}
