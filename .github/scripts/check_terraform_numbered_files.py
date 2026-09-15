#!/usr/bin/env python3
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

"""Ensure every committed Terraform file starts with a 3-digit numeric prefix.

Files living inside any directory called ``modules`` are exempt — they follow
their own naming convention.

Exit 0 when all files pass, 1 when at least one violation is found.

Usage (pre-commit passes matching filenames as positional arguments):
    python3 .github/scripts/check_terraform_numbered_files.py <file> [<file>…]
"""

import re
import sys
from pathlib import Path

# Matches basenames like "010-provider.tf", "020-variables.tf", "100-outputs.tf"
_PREFIX_RE = re.compile(r"^\d{3}-")


def _is_exempt(path: Path) -> bool:
    """Return True for files inside any directory named 'modules'."""
    return "modules" in path.parts


def check(files: list[str]) -> int:
    """Check each file and return the number of violations."""
    violations = 0
    for raw in files:
        path = Path(raw)
        if _is_exempt(path):
            continue
        if not _PREFIX_RE.match(path.name):
            print(
                f"ERROR: {raw} does not follow the 3-digit naming convention "
                "(e.g., 010-provider.tf, 020-variables.tf, 100-outputs.tf)"
            )
            violations += 1
    return violations


def main() -> None:
    sys.exit(0 if check(sys.argv[1:]) == 0 else 1)


if __name__ == "__main__":
    main()
