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

output "alb_external_address" {
  description = "Public IPv4 address of the Application Load Balancer, allocated by the load balancer itself."
  value       = stackit_application_load_balancer.this.external_address
}

output "project_id" {
  description = "ID of the project created inside the network area."
  value       = local.project_id
}

output "network_area_id" {
  description = "ID of the STACKIT Network Area."
  value       = stackit_network_area.this.network_area_id
}

output "managed_rule_set_name" {
  description = "Name of the managed rule set."
  value       = stackit_alb_waf_managed_rule_set.this.name
}

output "managed_rule_set_version" {
  description = "Version of the OWASP Core Rule Set the managed rule set is built from."
  value       = data.stackit_alb_waf_managed_rule_set.effective.version
}

output "managed_rule_mode_counts" {
  description = "Number of rules of the managed rule set per mode, read after the modes were set."
  value = {
    for mode in distinct([for rule in values(local.managed_rules_effective) : rule.mode]) :
    mode => length([for rule in values(local.managed_rules_effective) : rule if rule.mode == mode])
  }
}

output "managed_rule_overrides" {
  description = "Rules of the managed rule set that are not in MODE_ENABLED, read after the modes were set."
  value       = { for rule_id, rule in local.managed_rules_effective : rule_id => rule if rule.mode != "MODE_ENABLED" }
}

output "backend_private_ips" {
  description = "Private IPv4 addresses of the backend VMs, keyed by backend index."
  value       = { for key, nic in stackit_network_interface.backend : key => nic.ipv4 }
}
