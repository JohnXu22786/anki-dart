#!/usr/bin/env python3
# SPDX-License-Identifier: AGPL-3.0-or-later
"""Check SQL package AGPL metadata and pinned Anki Core provenance."""

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
COMMIT = "e64c6b1aee3e8d668fb8bbe084beada8e070d985"
SOURCES = {
    "rslib/src/search/sqlwriter.rs": "dd3614803244132a7379202dcdfe28e20973186d2bba28dd86faf4e1c424d4ec",
    "rslib/src/storage/deck/mod.rs": "f55e715844e364b530b292d3a7e7dfddcad4abe9a81b778f788e1224932edc0d",
    "rslib/src/storage/mod.rs": "f86526b51f16e48049951c203aae3e95e700981b3246180409e6c9c7b3096a5a",
    "rslib/src/search/parser.rs": "2b671bedbf3219dda8190d0a126aa78807a77ecd8c72ebc008ffb40d28e1a6b6",
    "rslib/src/timestamp.rs": "31929938c48febe39f445fa61e8aa0d134e0c93b6bdec5aad8250f5f931720b5",
    "rslib/src/card/mod.rs": "cfe294e1c65394f0b5c627b1e029b9d88bdf63de6fb3a29ba5a0253cd3f61ba9",
    "rslib/src/text.rs": "2b60699e1c6ad478baf80bfa50a85e9772f40279400d62c84b071c72945b1762",
    "rslib/src/decks/name.rs": "0a4e33f5a92d2c479c4cbd59664b0de30a50a41453dbe131fc9c809f5afc5f4d",
}


def main() -> int:
    errors = []
    expected = "".join(f"{digest}  {path}\n" for path, digest in SOURCES.items())
    if (ROOT / "SOURCE.sha256").read_text(encoding="utf-8") != expected:
        errors.append("SOURCE.sha256: pinned source digests are incorrect")
    notice = (ROOT / "NOTICE.md").read_text(encoding="utf-8")
    for required in (COMMIT, "Ankitects Pty Ltd and contributors", "GNU Affero General Public License"):
        if required not in notice:
            errors.append(f"NOTICE.md: missing {required!r}")
    license_text = (ROOT / "LICENSE").read_text(encoding="utf-8")
    if "GNU AFFERO GENERAL PUBLIC LICENSE" not in license_text or "Version 3" not in license_text:
        errors.append("LICENSE: complete GNU AGPL license text is missing")
    pubspec = (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
    if not re.search(r"^license:\s*AGPL-3\.0-or-later\s*$", pubspec, re.MULTILINE):
        errors.append("pubspec.yaml: license must be AGPL-3.0-or-later")
    for directory in ("lib", "test", "tool"):
        for path in sorted((ROOT / directory).rglob("*.dart")):
            content = path.read_text(encoding="utf-8")
            if not content.startswith("// SPDX-License-Identifier: AGPL-3.0-or-later\n"):
                errors.append(f"{path.relative_to(ROOT)}: AGPL SPDX header is missing")
            if "dart:io" in content or "package:flutter/" in content:
                errors.append(f"{path.relative_to(ROOT)}: platform-specific dependency is forbidden")
    if errors:
        print("Search SQL package validation failed:", file=sys.stderr)
        print("\n".join(f"- {error}" for error in errors), file=sys.stderr)
        return 1
    print("Validated AGPL metadata, platform-neutral Dart, and pinned Anki Core source hashes.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
