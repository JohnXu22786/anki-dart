#!/usr/bin/env python3
# SPDX-License-Identifier: AGPL-3.0-or-later
"""Check this package's pinned upstream source and standalone license metadata."""

from hashlib import sha256
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
SOURCE_COMMIT = "e64c6b1aee3e8d668fb8bbe084beada8e070d985"
SOURCE_HASHES = {
    "rslib/src/card/mod.rs": "cfe294e1c65394f0b5c627b1e029b9d88bdf63de6fb3a29ba5a0253cd3f61ba9",
    "rslib/src/card/service.rs": "8ddddbf879e08cb70ea00e9f00ac6c98f9f3988af65c48598a6cbb2fc11558b6",
    "rslib/src/notes/mod.rs": "5df79b58906206a87c5a28a06f886227df74e6a65d061d2cb915d35b34d35893",
    "rslib/src/notetype/mod.rs": "4f133ddf970d954e80cf3352d5bd91bf73418a1d71eaa1fb863218569d4198cb",
    "rslib/src/notetype/service.rs": "6fc566d68509e21ae4b294bf6fe45c3f458d81eb459c454e2faf9c6c19c44b9f",
    "rslib/src/notetype/fields.rs": "531d82f2917cab0d27828e2477ee51f4f533e9f81a499dcb2bc5632be6262a3a",
    "rslib/src/notetype/templates.rs": "b04ee6f16a250d5ee5649e6ef122f5ecfeab5d7aebaf80d4d31093ca96e9b241",
}


def main() -> int:
    errors: list[str] = []
    notice = ROOT / "NOTICE.md"
    notice_text = notice.read_text(encoding="utf-8") if notice.is_file() else ""
    if SOURCE_COMMIT not in notice_text:
        errors.append("NOTICE.md: pinned Anki Core source commit is missing")
    if "Ankitects Pty Ltd and contributors" not in notice_text:
        errors.append("NOTICE.md: upstream attribution is missing")
    if "GNU Affero" not in notice_text or "Public License" not in notice_text:
        errors.append("NOTICE.md: AGPL notice is missing")

    source_record = ROOT / "SOURCE.sha256"
    actual: dict[str, str] = {}
    if source_record.is_file():
        for line in source_record.read_text(encoding="utf-8").splitlines():
            match = re.fullmatch(r"([0-9a-f]{64})  (rslib/src/[a-z/]+\.rs)", line)
            if not match:
                errors.append(f"SOURCE.sha256: invalid entry {line!r}")
                continue
            actual[match.group(2)] = match.group(1)
        if actual != SOURCE_HASHES:
            errors.append("SOURCE.sha256: entries do not match the pinned upstream file hashes")
    else:
        errors.append("SOURCE.sha256: source digest manifest is missing")

    license_text = (ROOT / "LICENSE").read_text(encoding="utf-8") if (ROOT / "LICENSE").is_file() else ""
    if "GNU AFFERO GENERAL PUBLIC LICENSE" not in license_text or "Version 3" not in license_text:
        errors.append("LICENSE: complete GNU AGPL version 3 text is missing")
    pubspec = (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
    if not re.search(r"^license:\s*AGPL-3\.0-or-later\s*$", pubspec, re.MULTILINE):
        errors.append("pubspec.yaml: license must be AGPL-3.0-or-later")

    for path in sorted((ROOT / "lib").rglob("*.dart")):
        text = path.read_text(encoding="utf-8")
        if "import 'dart:io'" in text or 'import "dart:io"' in text:
            errors.append(f"{path.relative_to(ROOT)}: VM-only dart:io import is forbidden")
    if not (ROOT / "lib" / "anki_backend_models.dart").is_file():
        errors.append("lib/anki_backend_models.dart: public model export is missing")

    if errors:
        print("Model package validation failed:", file=sys.stderr)
        print("\n".join(f"- {error}" for error in errors), file=sys.stderr)
        return 1
    print("Validated pinned Anki model source hashes, AGPL metadata, and platform-neutral imports.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
