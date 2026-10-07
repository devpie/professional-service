#!/bin/sh
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

# Egress probe of the target. Terraform passes this script to the server as
# cloud-init user data of the type cloud-boothook. cloud-init runs a boothook
# on every boot, during its network stage and before any of its modules.
#
# The probe writes one line to the kernel log for every new outbound
# connection: destination address, protocol, destination port and the user ID
# of the socket. It changes no verdict and drops nothing.
#
# The script writes two files and loads the first one:
#   /etc/egress-probe.nft                nftables rule set of the probe
#   /usr/local/bin/egress-probe-report   prints the distinct destinations
#
# cloud-init reads metadata, user data and vendor data from the metadata
# service before it runs this script. The probe does not see those requests.
#
# The script always ends with exit status 0, so a machine without nft still
# finishes cloud-init without an error. The report tells whether the rule set
# is loaded.

ruleset=/etc/egress-probe.nft
report=/usr/local/bin/egress-probe-report

cat >"$ruleset" <<'RULESET'
# Egress probe: logs every new outbound connection that leaves the machine.
# The chain has no rule with a verdict and its policy is accept.

# Declare the table, then delete it: loading this file again replaces the
# table instead of adding the rule a second time.
table inet egress_probe
delete table inet egress_probe

table inet egress_probe {
    chain output {
        type filter hook output priority filter; policy accept;
        oifname != "lo" ct state new log prefix "egress-probe: " level info flags skuid
    }
}
RULESET

cat >"$report" <<'REPORT'
#!/bin/sh
# Prints one line for every distinct destination in the log of the egress
# probe: number of new connections, destination address, protocol, destination
# port and the user that owns the socket.
#
# Arguments are passed to journalctl. Without arguments the report covers all
# boots; "egress-probe-report --boot" covers the current boot.

if [ "$(id -u)" -ne 0 ]; then
    echo "error: run as root: sudo egress-probe-report" >&2
    exit 1
fi

if ! nft list table inet egress_probe >/dev/null 2>&1; then
    echo "warning: the rule set /etc/egress-probe.nft is not loaded, the probe logs nothing" >&2
fi

journalctl --no-pager --output=cat _TRANSPORT=kernel "$@" | awk '
    /egress-probe: / {
        destination = "-"; protocol = "-"; port = "-"; uid = "-"
        for (i = 1; i <= NF; i++) {
            if ($i ~ /^DST=/) destination = substr($i, 5)
            else if ($i ~ /^PROTO=/) protocol = substr($i, 7)
            else if ($i ~ /^DPT=/) port = substr($i, 5)
            else if ($i ~ /^UID=/) uid = substr($i, 5)
        }
        connections[destination " " protocol " " port " " uid]++
    }
    END {
        for (key in connections) print connections[key], key
    }' | sort -k2,2 -k3,3 -k4,4n -k5,5 | {
    printf '%-6s %-40s %-6s %-6s %s\n' COUNT DESTINATION PROTO PORT USER
    while read -r count destination protocol port uid; do
        user=$(getent passwd "$uid" | cut -d: -f1)
        printf '%-6s %-40s %-6s %-6s %s\n' "$count" "$destination" "$protocol" "$port" "${user:-$uid}"
    done
}
REPORT
chmod 0755 "$report"

if nft -f "$ruleset"; then
    echo "egress-probe: rule set loaded"
else
    echo "egress-probe: cannot load $ruleset" >&2
fi

exit 0
