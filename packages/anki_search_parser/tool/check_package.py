#!/usr/bin/env python3
# SPDX-License-Identifier: AGPL-3.0-or-later
"""Validate the parser package's pinned source and AGPL provenance."""

from hashlib import sha256
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
SOURCES = {
    "rslib/src/search/builder.rs": "0b5fe9ca6b2113849321620e31b26ba3b1f1c785237f8a7768bdd68ab8e524d2",
    "rslib/src/search/parser.rs": "2b671bedbf3219dda8190d0a126aa78807a77ecd8c72ebc008ffb40d28e1a6b6",
    "rslib/src/search/writer.rs": "82cbfd2d92746da726ebffc3fe63749c620b428292ce32220dfd09ff6662d195",
    "rslib/src/text.rs": "2b60699e1c6ad478baf80bfa50a85e9772f40279400d62c84b071c72945b1762",
}
COMMIT = "e64c6b1aee3e8d668fb8bbe084beada8e070d985"


def main() -> int:
    errors = []
    manifest = ROOT / "SOURCE.sha256"
    expected = "".join(f"{digest}  {path}\n" for path, digest in SOURCES.items())
    if not manifest.is_file() or manifest.read_text(encoding="utf-8") != expected:
        errors.append("SOURCE.sha256: pinned parser source digest is incorrect")
    notice = (ROOT / "NOTICE.md").read_text(encoding="utf-8")
    for required in (COMMIT, "Ankitects Pty Ltd and contributors", "GNU Affero", "Public License"):
        if required not in notice:
            errors.append(f"NOTICE.md: missing provenance text {required!r}")
    license_text = (ROOT / "LICENSE").read_text(encoding="utf-8")
    if "GNU AFFERO GENERAL PUBLIC LICENSE" not in license_text or "Version 3" not in license_text:
        errors.append("LICENSE: complete GNU AGPL v3 text is missing")
    pubspec = (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
    if not re.search(r"^license:\s*AGPL-3\.0-or-later\s*$", pubspec, re.MULTILINE):
        errors.append("pubspec.yaml: license must be AGPL-3.0-or-later")
    for directory in ("lib", "test", "tool"):
        for path in sorted((ROOT / directory).rglob("*.dart")):
            text = path.read_text(encoding="utf-8")
            if not text.startswith("// SPDX-License-Identifier: AGPL-3.0-or-later\n"):
                errors.append(f"{path.relative_to(ROOT)}: AGPL SPDX header missing")
            if "dart:io" in text or "package:flutter/" in text:
                errors.append(f"{path.relative_to(ROOT)}: VM/Flutter dependency forbidden")
    if errors:
        print("Search parser package validation failed:", file=sys.stderr)
        print("\n".join(f"- {e}" for e in errors), file=sys.stderr)
        return 1
    print("Validated AGPL metadata and pinned Anki Core parser/writer source hashes.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
