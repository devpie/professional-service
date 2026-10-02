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

# --- managed rule set ----------------------------------------------------
#
# A managed rule set is a copy of the OWASP Core Rule Set (CRS) that STACKIT
# maintains. TYPE_OWASP_CRS is the only type. The rules cannot be edited and no
# rules can be added; each rule has a mode that can be changed. A new managed
# rule set has every rule in MODE_ENABLED.
resource "stackit_alb_waf_managed_rule_set" "this" {
  project_id = local.project_id
  region     = var.stackit_region
  name       = "${var.name_prefix}-crs"
  type       = "TYPE_OWASP_CRS"
}

locals {
  managed_rule_set_url = "https://alb-waf.api.stackit.cloud/v1/projects/${local.project_id}/regions/${var.stackit_region}/managed-rule-sets/${stackit_alb_waf_managed_rule_set.this.name}"

  managed_rule_ids = flatten([
    for group in values(stackit_alb_waf_managed_rule_set.this.groups) : keys(group.rules)
  ])

  # The request body lists every rule of the rule set with its desired mode.
  # A rule that is removed from managed_rule_modes therefore returns to
  # MODE_ENABLED on the next apply.
  managed_rule_set_patch = {
    groups = {
      for group_id, group in stackit_alb_waf_managed_rule_set.this.groups : group_id => {
        rules = {
          for rule_id, rule in group.rules : rule_id => {
            mode = lookup(var.managed_rule_modes, rule_id, "MODE_ENABLED")
          }
        }
      }
    }
  }
}

# The token of the service account the provider is configured with. An
# ephemeral resource is not written to the plan or the state.
ephemeral "stackit_access_token" "waf" {}

# stackit_alb_waf_managed_rule_set exposes the rules read-only and has no
# update. The modes are set with a PATCH request against the WAF API instead.
# The request runs again whenever the request body changes or the managed rule
# set is replaced.
resource "terraform_data" "managed_rule_modes" {
  triggers_replace = sha256(jsonencode(local.managed_rule_set_patch))

  lifecycle {
    replace_triggered_by = [stackit_alb_waf_managed_rule_set.this]

    precondition {
      condition     = length(setsubtract(keys(var.managed_rule_modes), local.managed_rule_ids)) == 0
      error_message = "managed_rule_modes lists rule IDs that the managed rule set does not contain: ${join(", ", setsubtract(keys(var.managed_rule_modes), local.managed_rule_ids))}."
    }
  }

  # The request is idempotent. curl repeats it on a timeout and on the status
  # codes 408, 429, 500, 502, 503 and 504.
  provisioner "local-exec" {
    command = <<-EOT
      printf '%s' "$MANAGED_RULE_SET_PATCH" | curl --silent --show-error --fail \
        --retry 5 --retry-delay 5 --max-time 60 \
        --request PATCH \
        --header "Authorization: Bearer $STACKIT_ACCESS_TOKEN" \
        --header "Content-Type: application/json" \
        --data-binary @- \
        --output /dev/null \
        "$MANAGED_RULE_SET_URL"
    EOT

    environment = {
      MANAGED_RULE_SET_URL   = local.managed_rule_set_url
      MANAGED_RULE_SET_PATCH = jsonencode(local.managed_rule_set_patch)
      STACKIT_ACCESS_TOKEN   = ephemeral.stackit_access_token.waf.access_token
    }
  }
}

# Reads the managed rule set after the PATCH request.
# stackit_alb_waf_managed_rule_set.this still holds the modes from before the
# request until the next refresh.
data "stackit_alb_waf_managed_rule_set" "effective" {
  project_id = local.project_id
  region     = var.stackit_region
  name       = stackit_alb_waf_managed_rule_set.this.name

  depends_on = [terraform_data.managed_rule_modes]
}

locals {
  managed_rules_effective = merge([
    for group_id, group in data.stackit_alb_waf_managed_rule_set.effective.groups : {
      for rule_id, rule in group.rules : rule_id => {
        group       = "${group_id} ${group.group_name}"
        description = rule.description
        severity    = rule.severity
        mode        = rule.mode
      }
    }
  ]...)

  managed_rules_deviating = [
    for rule_id, rule in local.managed_rules_effective : rule_id
    if rule.mode != lookup(var.managed_rule_modes, rule_id, "MODE_ENABLED")
  ]
}

# The modes can also be changed with the CLI or through the API. Terraform
# does not revert such a change on its own; this check reports it as a
# warning on plan and apply.
check "managed_rule_modes" {
  assert {
    condition     = length(local.managed_rules_deviating) == 0
    error_message = "These rules of the managed rule set are not in the mode this configuration asks for: ${join(", ", local.managed_rules_deviating)}. Run `terraform apply -replace=terraform_data.managed_rule_modes` to set them again."
  }
}

# --- WAF configuration ---------------------------------------------------
#
# A listener of the load balancer refers to the WAF configuration by name. The
# configuration applies the managed rule set above. It can also reference a
# custom rule group with rules of your own, which this example does not use.
resource "stackit_alb_waf_configuration" "this" {
  project_id            = local.project_id
  region                = var.stackit_region
  name                  = "${var.name_prefix}-waf"
  managed_rule_set_name = stackit_alb_waf_managed_rule_set.this.name
  labels                = local.labels
}
