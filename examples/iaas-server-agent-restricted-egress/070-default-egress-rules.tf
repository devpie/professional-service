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

# STACKIT adds two egress rules to every new security group. One allows all
# outbound IPv4 traffic, the other all outbound IPv6 traffic. Rules only
# allow, so the allow-list in 060-security-groups.tf restricts nothing while
# these two rules exist.
#
# The provider cannot remove them: stackit_security_group has no argument for
# its rules, and the data source does not list them. This file removes them
# with two calls against the IaaS API.

# Holds the mode, so that other resources can react to a change of it. The
# target's security group, network interface and server are replaced when it
# changes: the new group starts with its default rules again, and the new
# server boots for the first time under the rule set of the new mode.
resource "terraform_data" "egress_mode" {
  input = var.egress_mode
}

# The token of the service account the provider is configured with. An
# ephemeral resource is not written to the plan or the state.
ephemeral "stackit_access_token" "iaas" {}

# Runs once per security group, in mode "restricted" only. The script deletes
# every egress rule that has no protocol, no port range, no IP range and no
# remote security group, and fails unless the group is then free of egress
# rules that allow all traffic. It needs bash, curl and jq on the machine that
# runs Terraform.
#
# Terraform hides the output of the script, because its environment holds the
# token. When the script fails, the error message of Terraform contains the
# output.
resource "terraform_data" "remove_default_egress_rules" {
  count = var.egress_mode == "restricted" ? 1 : 0

  triggers_replace = stackit_security_group.target.security_group_id

  provisioner "local-exec" {
    interpreter = ["bash"]
    command     = "${path.module}/scripts/remove-default-egress-rules.sh"

    environment = {
      SECURITY_GROUP_URL   = "https://iaas.api.stackit.cloud/v2/projects/${stackit_security_group.target.project_id}/regions/${stackit_security_group.target.region}/security-groups/${stackit_security_group.target.security_group_id}"
      STACKIT_ACCESS_TOKEN = ephemeral.stackit_access_token.iaas.access_token
    }
  }
}
