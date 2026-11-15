# Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
# SPDX-License-Identifier: GPL-3.0-or-later

#!/usr/bin/env python3
"""Check SPDX tags on Dart sources and the repository GPL license texts."""

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parent.parent
EXPECTED_IDENTIFIERS = {
    "GPL-3.0-or-later",
    "LicenseRef-Unicode-License-V3",
}


def main() -> int:
    errors: list[str] = []
    dart_files = sorted((*((ROOT / "lib").rglob("*.dart")), *((ROOT / "test").rglob("*.dart"))))
    for path in dart_files:
        text = path.read_text(encoding="utf-8")
        match = re.search(r"^\s*(?://|/\*|\*)?\s*SPDX-License-Identifier:\s*([^\s*]+)\s*$", text, re.MULTILINE)
        relative = path.relative_to(ROOT)
        if match is None:
            errors.append(f"{relative}: missing SPDX-License-Identifier")
        elif match.group(1) not in EXPECTED_IDENTIFIERS:
            errors.append(f"{relative}: unsupported SPDX identifier {match.group(1)}")

    copying = ROOT / "COPYING"
    gpl_text = ROOT / "LICENSES" / "GPL-3.0-or-later.txt"
    for path in (copying, gpl_text):
        if not path.is_file():
            errors.append(f"{path.relative_to(ROOT)}: required license file is missing")
            continue
        text = path.read_text(encoding="utf-8")
        if "GNU GENERAL PUBLIC LICENSE" not in text:
            errors.append(f"{path.relative_to(ROOT)}: missing GNU GPL title")
        if "Version 3" not in text or "29 June 2007" not in text:
            errors.append(f"{path.relative_to(ROOT)}: missing GPL version and date")
        if "END OF TERMS AND CONDITIONS" not in text:
            errors.append(f"{path.relative_to(ROOT)}: missing GPL terms closing marker")

    unicode_license = ROOT / "LICENSES" / "Unicode-License-V3.txt"
    if not unicode_license.is_file() or unicode_license.stat().st_size == 0:
        errors.append("LICENSES/Unicode-License-V3.txt: required license file is missing or empty")

    # This unit's CI contract keeps the root GPL text untouched relative to main.
    # `actions/checkout` fetches complete history and origin/main is the PR target.
    import subprocess

    result = subprocess.run(
        ["git", "diff", "--quiet", "origin/main...HEAD", "--", "COPYING"],
        cwd=ROOT,
        check=False,
    )
    if result.returncode == 1:
        errors.append("COPYING: changed from origin/main")
    elif result.returncode != 0:
        errors.append("COPYING: unable to compare with origin/main")

    if errors:
        print("License validation failed:", file=sys.stderr)
        print("\n".join(f"- {error}" for error in errors), file=sys.stderr)
        return 1

    print(f"Validated SPDX tags on {len(dart_files)} Dart files and GPL COPYING/license texts.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
