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

# STACKIT adds two egress rules to every new security group, one for IPv4 and
# one for IPv6. Both allow all outbound traffic, so the allow-list in
# 060-security-groups.tf restricts nothing while they exist. The provider
# cannot remove them, so this file deletes them through the IaaS API.

# This ephemeral resource returns a token for the service account that the
# provider uses. Terraform writes it neither to the plan nor to the state.
ephemeral "stackit_access_token" "iaas" {}

# Runs remove-default-egress-rules.sh for the target's security group, and
# again when Terraform replaces that group. The script needs bash, curl 7.55.0
# or later and jq on the machine that runs Terraform.
resource "terraform_data" "remove_default_egress_rules" {
  triggers_replace = stackit_security_group.target.security_group_id

  provisioner "local-exec" {
    interpreter = ["bash"]
    command     = "${path.module}/remove-default-egress-rules.sh"

    environment = {
      SECURITY_GROUP_URL   = "https://iaas.api.stackit.cloud/v2/projects/${stackit_security_group.target.project_id}/regions/${stackit_security_group.target.region}/security-groups/${stackit_security_group.target.security_group_id}"
      STACKIT_ACCESS_TOKEN = ephemeral.stackit_access_token.iaas.access_token
    }
  }
}
