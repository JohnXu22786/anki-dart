#!/usr/bin/env python3
# SPDX-License-Identifier: AGPL-3.0-or-later
"""Check package licensing metadata and Dart source headers."""

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
SOURCE_HASHES = {
    "rslib/src/storage/sqlite.rs": "877e18ef2ddcc497a91fca0c2a84d2f22658f09582d8c7f2ba1f03ca2d4ba73c",
    "rslib/src/text.rs": "2b60699e1c6ad478baf80bfa50a85e9772f40279400d62c84b071c72945b1762",
    "rslib/src/cloze.rs": "478a35d1248be262ed2d0941202ac8f201c7eb0a5c57b7198d3ace03898fd1c5",
}


def main() -> int:
    errors: list[str] = []
    pubspec = (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
    if not re.search(r"^license:\s*AGPL-3\.0-or-later\s*$", pubspec, re.MULTILINE):
        errors.append("pubspec.yaml: license must be AGPL-3.0-or-later")

    license_text = (ROOT / "LICENSE").read_text(encoding="utf-8")
    if "GNU AFFERO GENERAL PUBLIC LICENSE" not in license_text or "Version 3" not in license_text:
        errors.append("LICENSE: complete GNU AGPL version 3 text is missing")

    manifest = {}
    for line in (ROOT / "SOURCE.sha256").read_text(encoding="utf-8").splitlines():
        match = re.fullmatch(r"([0-9a-f]{64})  (rslib/src/[a-z0-9_/.]+\.(?:sql|rs))", line)
        if not match:
            errors.append(f"SOURCE.sha256: invalid entry {line!r}")
            continue
        manifest[match.group(2)] = match.group(1)
    for source, digest in SOURCE_HASHES.items():
        if manifest.get(source) != digest:
            errors.append(f"SOURCE.sha256: Core source hash differs from the pinned source: {source}")

    for directory in ("lib", "test", "tool"):
        for path in sorted((ROOT / directory).rglob("*.dart")):
            text = path.read_text(encoding="utf-8")
            if not text.startswith("// SPDX-License-Identifier: AGPL-3.0-or-later\n"):
                errors.append(f"{path.relative_to(ROOT)}: AGPL SPDX header is missing")
    common = (ROOT / "lib" / "src" / "collection_sqlite_storage.dart").read_text(
        encoding="utf-8"
    )
    if "dart:io" in common:
        errors.append("common adapter: dart:io is not portable to Web")

    if errors:
        print("Collection SQLite package validation failed:", file=sys.stderr)
        print("\n".join(f"- {error}" for error in errors), file=sys.stderr)
        return 1
    print("Validated AGPL metadata, pinned Core source hashes, and Dart SPDX headers.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
