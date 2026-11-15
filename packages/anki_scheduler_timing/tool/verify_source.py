#!/usr/bin/env python3
# SPDX-License-Identifier: AGPL-3.0-or-later
"""Verify pinned Anki Core source hashes and package license metadata.

Pass an Anki Core checkout path to verify the files against the manifest.
"""

from pathlib import Path
from hashlib import sha256
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
SOURCE_COMMIT = "e64c6b1aee3e8d668fb8bbe084beada8e070d985"
SOURCE_HASHES = {
    "rslib/src/scheduler/timing.rs": "a9aeea597aa76b57a90bf91124d4245bde91c672f60e56337460a60300795f17",
    "rslib/src/timestamp.rs": "31929938c48febe39f445fa61e8aa0d134e0c93b6bdec5aad8250f5f931720b5",
}


def main() -> int:
    source_root = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else None
    errors: list[str] = []
    manifest: dict[str, str] = {}
    for line in (ROOT / "SOURCE.sha256").read_text(encoding="utf-8").splitlines():
        match = re.fullmatch(r"([0-9a-f]{64})  (rslib/src/[a-z0-9_/.]+\.rs)", line)
        if not match:
            errors.append(f"SOURCE.sha256: invalid entry {line!r}")
            continue
        manifest[match.group(2)] = match.group(1)
    if manifest != SOURCE_HASHES:
        errors.append("SOURCE.sha256: hashes do not match pinned Anki Core sources")
    if source_root is not None:
        for source, expected in SOURCE_HASHES.items():
            path = source_root / source
            if not path.is_file() or sha256(path.read_bytes()).hexdigest() != expected:
                errors.append(f"pinned source hash mismatch: {source}")

    notice = (ROOT / "NOTICE.md").read_text(encoding="utf-8")
    for required in (SOURCE_COMMIT, "Ankitects Pty Ltd and contributors", "GNU Affero"):
        if required not in notice:
            errors.append(f"NOTICE.md: missing {required!r}")

    license_text = (ROOT / "LICENSE").read_text(encoding="utf-8")
    if "GNU AFFERO GENERAL PUBLIC LICENSE" not in license_text or "Version 3" not in license_text:
        errors.append("LICENSE: complete GNU AGPL version 3 text is missing")
    pubspec = (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
    if not re.search(r"^license:\s*AGPL-3\.0-or-later\s*$", pubspec, re.MULTILINE):
        errors.append("pubspec.yaml: license must be AGPL-3.0-or-later")

    for folder in ("lib", "test", "tool"):
        for path in sorted((ROOT / folder).rglob("*.dart")):
            source = path.read_text(encoding="utf-8")
            if not source.startswith("// SPDX-License-Identifier: AGPL-3.0-or-later\n"):
                errors.append(f"{path.relative_to(ROOT)}: AGPL SPDX header is missing")
            if folder == "lib" and re.search(r"import ['\"]dart:io['\"]", source):
                errors.append(f"{path.relative_to(ROOT)}: dart:io is not platform-neutral")

    if errors:
        print("Scheduler timing package validation failed:", file=sys.stderr)
        print("\n".join(f"- {error}" for error in errors), file=sys.stderr)
        return 1
    print(f"Validated {len(SOURCE_HASHES)} pinned sources, AGPL metadata, and Dart SPDX headers.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
