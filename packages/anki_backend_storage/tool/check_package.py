#!/usr/bin/env python3
# SPDX-License-Identifier: AGPL-3.0-or-later
"""Validate source attribution, SQL hashes, license metadata, and SPDX tags."""

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
EXPECTED = {
    "rslib/src/storage/note/mod.rs": "e875a63c641393c0a6904872bd55ebe164a4eceff8aa07686ca246fe6d54de23",
    "rslib/src/storage/note/add.sql": "ff00ce1fa18a610726b5af77103feaef9a5dc36c27f4b8b515643b96c21af2a4",
    "rslib/src/storage/note/update.sql": "7a4ff39a4232e4643d67721b0cf4965e59d6d8da6bd93294a6ae121b37215561",
    "rslib/src/storage/note/add_if_unique.sql": "4ddddc9324b5ff5801a786f7c1a11461345510e63789048928fbda186fe7022c",
    "rslib/src/storage/note/add_or_update.sql": "dcc75fd0e5b19849056108253dce2cb4bd52dd14cac3ae99c709bbc127209b96",
}


def main() -> int:
    errors: list[str] = []
    source_file = ROOT / "SOURCE.sha256"
    recorded = {}
    if source_file.is_file():
        for line in source_file.read_text(encoding="utf-8").splitlines():
            match = re.fullmatch(r"([0-9a-f]{64})  (rslib/src/storage/note/[a-z_]+\.(?:rs|sql))", line)
            if match is None:
                errors.append(f"SOURCE.sha256: invalid entry {line!r}")
            else:
                recorded[match.group(2)] = match.group(1)
    else:
        errors.append("SOURCE.sha256: missing source manifest")
    if recorded != EXPECTED:
        errors.append("SOURCE.sha256: source entries do not match pinned Anki Core hashes")
    notice = (ROOT / "NOTICE.md").read_text(encoding="utf-8")
    if "Ankitects Pty Ltd and contributors" not in notice or "GNU Affero" not in notice:
        errors.append("NOTICE.md: upstream attribution or AGPL notice is missing")
    if not re.search(
        r"^license:\s*AGPL-3\.0-or-later\s*$",
        (ROOT / "pubspec.yaml").read_text(encoding="utf-8"),
        re.MULTILINE,
    ):
        errors.append("pubspec.yaml: license must be AGPL-3.0-or-later")
    license_text = ROOT / "LICENSE"
    if not license_text.is_file() or "GNU AFFERO GENERAL PUBLIC LICENSE" not in license_text.read_text(encoding="utf-8"):
        errors.append("LICENSE: full GNU AGPL text is missing")

    for directory in ("lib", "test", "tool"):
        for path in sorted((ROOT / directory).rglob("*.dart")):
            if not path.read_text(encoding="utf-8").startswith(
                "// SPDX-License-Identifier: AGPL-3.0-or-later\n"
            ):
                errors.append(f"{path.relative_to(ROOT)}: AGPL SPDX header is missing")
            if directory == "lib" and "import 'dart:io'" in path.read_text(encoding="utf-8"):
                errors.append(f"{path.relative_to(ROOT)}: platform-specific dart:io import is forbidden")

    if errors:
        print("Storage package validation failed:", file=sys.stderr)
        print("\n".join(f"- {error}" for error in errors), file=sys.stderr)
        return 1
    print("Validated note storage source hashes, AGPL metadata, SPDX tags, and platform-neutral imports.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
