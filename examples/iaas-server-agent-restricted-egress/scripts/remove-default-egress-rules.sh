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

# Removes the default egress rules from one STACKIT security group.
#
# STACKIT adds two rules to every new security group: one allows all outbound
# IPv4 traffic, the other all outbound IPv6 traffic. The rules of a security
# group only allow, so an allow-list has no effect while these two exist. The
# Terraform provider neither creates nor shows them. This script reads the
# group through the IaaS API, deletes the two rules and then checks that no
# egress rule is left that allows all traffic.
#
# A default rule is an egress rule without protocol, port range, IP range and
# remote security group. The script deletes nothing else and never touches an
# ingress rule. A second run finds no default rule and only checks.
#
# Environment:
#   SECURITY_GROUP_URL    URL of the group in the IaaS API:
#                         https://iaas.api.stackit.cloud/v2/projects/<project>/regions/<region>/security-groups/<id>
#   STACKIT_ACCESS_TOKEN  access token of an identity that is allowed to edit the group
#   VERIFY_ATTEMPTS       optional: how often the final check reads the group (default 12)
#   VERIFY_DELAY_SECONDS  optional: pause between two checks (default 5)
#
# Requires bash, jq and curl 7.55.0 or later.
# Exit 0: no egress rule that allows all traffic is left. Exit 1: anything else.

set -euo pipefail

fail() {
  echo "error: $*" >&2
  exit 1
}

[[ -n "${SECURITY_GROUP_URL:-}" ]] || fail "SECURITY_GROUP_URL is not set"
[[ -n "${STACKIT_ACCESS_TOKEN:-}" ]] || fail "STACKIT_ACCESS_TOKEN is not set"
verify_attempts="${VERIFY_ATTEMPTS:-12}"
verify_delay="${VERIFY_DELAY_SECONDS:-5}"

for tool in curl jq; do
  command -v "$tool" >/dev/null 2>&1 || fail "$tool is required but not installed"
done

# An egress rule without protocol, port range and remote security group matches
# every packet to its IP range.
readonly unrestricted_egress='
  .rules[]
  | select(.direction == "egress")
  | select((.protocol // {}) | (.name == null and .number == null))
  | select(.portRange == null and .icmpParameters == null)
  | select(.remoteSecurityGroupId == null)'

# The default rules have no IP range at all.
readonly default_rule_ids="$unrestricted_egress | select(.ipRange == null) | .id"

# A rule to 0.0.0.0/0 or ::/0 has the same effect, but STACKIT did not create
# it. The script reports it instead of deleting it.
readonly foreign_rule_ids="$unrestricted_egress | select(.ipRange == \"0.0.0.0/0\" or .ipRange == \"::/0\") | .id"

# api METHOD URL [CURL_OPTION...]
# curl reads the Authorization header from a file descriptor, so the token does
# not show up in the process list. curl repeats a request on a timeout and on
# the status codes 408, 429, 500, 502, 503 and 504.
api() {
  local method="$1" url="$2"
  shift 2
  curl --silent --show-error --fail \
    --retry 5 --retry-delay 5 --max-time 60 \
    --request "$method" \
    --header @<(printf 'Authorization: Bearer %s\n' "$STACKIT_ACCESS_TOKEN") \
    --header "Accept: application/json" \
    "$@" "$url"
}

read_group() {
  local group
  group=$(api GET "$SECURITY_GROUP_URL") || fail "cannot read the security group at $SECURITY_GROUP_URL"
  jq -e '(.rules | type) == "array"' >/dev/null 2>&1 <<<"$group" ||
    fail "the answer of the IaaS API contains no list of rules"
  printf '%s' "$group"
}

group=$(read_group)
to_delete=$(jq -r "$default_rule_ids" <<<"$group")

deleted=0
while IFS= read -r rule_id; do
  [[ -n "$rule_id" ]] || continue
  # The API answers 404 when the rule is already gone, for example after curl
  # repeated a request whose first answer was lost.
  status=$(api DELETE "$SECURITY_GROUP_URL/rules/$rule_id" --output /dev/null --write-out '%{http_code}') ||
    [[ "$status" == "404" ]] ||
    fail "cannot delete the default egress rule $rule_id (HTTP status $status)"
  deleted=$((deleted + 1))
done <<<"$to_delete"

# The API accepts a deletion before the rule is gone, so the check reads the
# group until no default rule is listed any more.
attempt=1
while true; do
  group=$(read_group)

  foreign=$(jq -r "[$foreign_rule_ids] | join(\" \")" <<<"$group")
  [[ -z "$foreign" ]] ||
    fail "the group has an egress rule that allows all traffic and is not a default rule: $foreign. Delete it, then run again."

  pending=$(jq -r "[$default_rule_ids] | join(\" \")" <<<"$group")
  if [[ -z "$pending" ]]; then
    remaining=$(jq -r '[.rules[] | select(.direction == "egress")] | length' <<<"$group")
    echo "deleted $deleted default egress rule(s); no egress rule that allows all traffic is left, $remaining egress rule(s) remain"
    exit 0
  fi

  if ((attempt >= verify_attempts)); then
    fail "default egress rules are still listed after $verify_attempts checks: $pending"
  fi
  attempt=$((attempt + 1))
  sleep "$verify_delay"
done
