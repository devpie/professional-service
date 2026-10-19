#!/usr/bin/env bash
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

# Deletes the two default egress rules of one STACKIT security group: every
# egress rule without protocol, port range, IP range and remote security group.
# A rule that is already gone answers 404, for example after curl repeated a
# request whose answer was lost. The script then lists the rules every 5
# seconds until no default egress rule is left, and fails after 30 seconds.
# curl gives up on a request after 60 seconds and repeats it up to five times.
#
# Environment: SECURITY_GROUP_URL (the group in the IaaS API) and
# STACKIT_ACCESS_TOKEN. curl reads the header from a file descriptor, so the
# token does not appear in the command line of curl.
# Requires bash, curl 7.55.0 or later and jq.
set -euo pipefail

api() { curl -sSf --retry 5 --retry-delay 5 --max-time 60 -H @<(printf 'Authorization: Bearer %s\n' "$STACKIT_ACCESS_TOKEN") "$@"; }
default_rules='.items[] | select(.direction == "egress" and .protocol == null and .portRange == null and .ipRange == null and .remoteSecurityGroupId == null) | .id'

ids=$(api "$SECURITY_GROUP_URL/rules" | jq -r "$default_rules")
for id in $ids; do
  code=$(api -X DELETE -o /dev/null -w '%{http_code}' "$SECURITY_GROUP_URL/rules/$id") || [ "$code" = 404 ]
done

for _ in 1 2 3 4 5 6; do
  left=$(api "$SECURITY_GROUP_URL/rules" | jq -r "$default_rules")
  [ -z "$left" ] && exit 0
  sleep 5
done
echo "default egress rules still present: $left" >&2
exit 1
