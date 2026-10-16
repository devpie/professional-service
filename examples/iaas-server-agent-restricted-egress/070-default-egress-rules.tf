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

# This resource deletes every egress rule of the target's security group that
# has no protocol, no port range, no IP range and no remote security group.
# These are the two default egress rules. A rule that is already gone answers
# 404, for example after curl repeated a request whose answer was lost. The
# block then lists the rules every 5 seconds until no default egress rule is
# left, and fails after 30 seconds. curl gives up on a request after 60
# seconds and repeats it up to five times. Terraform runs the block again
# when it replaces the group. It needs bash, curl 7.55.0 or later and jq on
# the machine that runs Terraform. curl reads the header from a file
# descriptor, so the token does not appear in the command line of curl.
resource "terraform_data" "remove_default_egress_rules" {
  triggers_replace = stackit_security_group.target.security_group_id

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
      set -euo pipefail
      api() { curl -sSf --retry 5 --retry-delay 5 --max-time 60 -H @<(printf 'Authorization: Bearer %s\n' "$STACKIT_ACCESS_TOKEN") "$@"; }
      default_rules='.items[] | select(.direction == "egress" and .protocol == null and .portRange == null and .ipRange == null and .remoteSecurityGroupId == null) | .id'
      ids=$(api "$SECURITY_GROUP_URL/rules" | jq -r "$default_rules")
      for id in $ids; do
        code=$(api -X DELETE -o /dev/null -w '%%{http_code}' "$SECURITY_GROUP_URL/rules/$id") || [ "$code" = 404 ]
      done
      for _ in 1 2 3 4 5 6; do
        left=$(api "$SECURITY_GROUP_URL/rules" | jq -r "$default_rules")
        [ -z "$left" ] && exit 0
        sleep 5
      done
      echo "default egress rules still present: $left" >&2
      exit 1
    EOT

    environment = {
      SECURITY_GROUP_URL   = "https://iaas.api.stackit.cloud/v2/projects/${stackit_security_group.target.project_id}/regions/${stackit_security_group.target.region}/security-groups/${stackit_security_group.target.security_group_id}"
      STACKIT_ACCESS_TOKEN = ephemeral.stackit_access_token.iaas.access_token
    }
  }
}
