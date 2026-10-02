#!/bin/bash
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

# Runs 'terraform apply' and 'terraform plan' at the same time. Terraform takes
# the state lock before it does anything else, so the command that comes second
# is rejected. The script succeeds only if exactly that happened.

set -u

LOCK_ERROR="Error acquiring the state lock"
APPLY_LOG=$(mktemp)
PLAN_LOG=$(mktemp)
trap 'rm -f "$APPLY_LOG" "$PLAN_LOG"' EXIT

echo "[INFO] Starting 'terraform apply' in the background..."
terraform apply -auto-approve -input=false -no-color >"$APPLY_LOG" 2>&1 &
APPLY_PID=$!

echo "[INFO] Running 'terraform plan' at the same time..."
echo "[INFO] ------------------------------------------------------------------"
terraform plan -input=false -no-color 2>&1 | tee "$PLAN_LOG"
PLAN_EXIT_CODE=${PIPESTATUS[0]}
echo "[INFO] ------------------------------------------------------------------"

echo "[INFO] Waiting for the background 'terraform apply' to finish..."
wait "$APPLY_PID"
APPLY_EXIT_CODE=$?

if grep -q "$LOCK_ERROR" "$PLAN_LOG" && [ "$APPLY_EXIT_CODE" -eq 0 ]; then
  echo "[SUCCESS] 'terraform plan' was rejected while 'terraform apply' held the state lock."
  exit 0
fi

if grep -q "$LOCK_ERROR" "$APPLY_LOG" && [ "$PLAN_EXIT_CODE" -eq 0 ]; then
  echo "[SUCCESS] 'terraform apply' was rejected while 'terraform plan' held the state lock."
  echo "[INFO] The apply did not run. Run 'terraform apply' if the project does not exist yet."
  exit 0
fi

echo "[ERROR] Expected one command to be rejected with '$LOCK_ERROR' and the other one to succeed (plan exit code $PLAN_EXIT_CODE, apply exit code $APPLY_EXIT_CODE)."
echo "[ERROR] Output of 'terraform apply':"
cat "$APPLY_LOG"
exit 1
