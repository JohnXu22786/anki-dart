#!/usr/bin/env python3
# SPDX-License-Identifier: AGPL-3.0-or-later
"""Check this package's pinned upstream source and standalone license metadata."""

from hashlib import sha256
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
SOURCE_COMMIT = "e64c6b1aee3e8d668fb8bbe084beada8e070d985"
UNICODE_CASE_FOLDING = "9c772627c6ee77eea6a17b42927b8ee28ca05dc65d6a511062104baaf3d12294"
SOURCE_HASHES = {
    "rslib/src/card/mod.rs": "cfe294e1c65394f0b5c627b1e029b9d88bdf63de6fb3a29ba5a0253cd3f61ba9",
    "rslib/src/card/service.rs": "8ddddbf879e08cb70ea00e9f00ac6c98f9f3988af65c48598a6cbb2fc11558b6",
    "rslib/src/notes/mod.rs": "5df79b58906206a87c5a28a06f886227df74e6a65d061d2cb915d35b34d35893",
    "rslib/src/notetype/mod.rs": "4f133ddf970d954e80cf3352d5bd91bf73418a1d71eaa1fb863218569d4198cb",
    "rslib/src/notetype/stock.rs": "a2f5175e8dcff92c01bfc09ed30f0e085253b8de01be6769019e505f5704ae15",
    "rslib/src/image_occlusion/notetype.rs": "89bd6609de21422b5e8de1f7cba0f693b24476a85401dc89ff7812b48375eff9",
    "rslib/src/image_occlusion/notetype.css": "18637cbc7996bb06e803239f99cd56befa7707035fa05f63ca44f62aba83e9ad",
    "rslib/src/notetype/cloze_styling.css": "17d12d52e6321d5f17be18911f47433110d39e9a52d23eeb13bfe7787932639d",
    "rslib/src/notetype/header.tex": "9e1dcea96178f505ec330c20efea94e11350d671f245612bc8cae1960e9223b7",
    "rslib/src/notetype/styling.css": "e50d4c220958517e9418a1bfe849fe0f3fc74a507600aafe00fc9d7a94733740",
    "rslib/src/notetype/service.rs": "6fc566d68509e21ae4b294bf6fe45c3f458d81eb459c454e2faf9c6c19c44b9f",
    "rslib/src/notetype/fields.rs": "531d82f2917cab0d27828e2477ee51f4f533e9f81a499dcb2bc5632be6262a3a",
    "rslib/src/notetype/templates.rs": "b04ee6f16a250d5ee5649e6ef122f5ecfeab5d7aebaf80d4d31093ca96e9b241",
    "rslib/src/decks/mod.rs": "dc5a90c3465b7216b6ad1e42a0c44a2d18a99beea777023adcb63cb4abdf38d4",
    "rslib/src/decks/name.rs": "0a4e33f5a92d2c479c4cbd59664b0de30a50a41453dbe131fc9c809f5afc5f4d",
    "rslib/src/decks/service.rs": "87c0df5a0a7f1307a55f46daac235868a994e96e9a7ae34f7322bb6c3d11bed5",
    "rslib/src/deckconfig/mod.rs": "1b85b99ae9188b5f8d2ccb6a23930bc636f86c1a775a564cd24d1017fcebcfac",
    "rslib/src/deckconfig/service.rs": "58b9d4da7924cfa95cec66061fe1b75be38c5109df710e6c01d22cbb0bceb4be",
    "rslib/src/media/mod.rs": "bcf4529fbf244f506221cc45e0683f432e1366dacebf176cf2dda1616e581424",
    "rslib/src/sync/media/database/client/mod.rs": "e07639f5018eac52b29657dda99eb9e16f186e734b6b3e530c75f6af93059e81",
    "rslib/src/config/mod.rs": "4d288b43ebfb365e083f2fcf352e6c6a87b973c0e8fea8aedcef872db8bd03eb",
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
            match = re.fullmatch(
                r"([0-9a-f]{64})  (rslib/src/[a-z_/]+\.(?:rs|css|tex))", line
            )
            if not match:
                errors.append(f"SOURCE.sha256: invalid entry {line!r}")
                continue
            actual[match.group(2)] = match.group(1)
        if actual != SOURCE_HASHES:
            errors.append("SOURCE.sha256: entries do not match the pinned upstream file hashes")
    else:
        errors.append("SOURCE.sha256: source digest manifest is missing")

    unicode_manifest = ROOT / "UNICODE_CASEFOLD.sha256"
    expected_unicode_record = (
        f"{UNICODE_CASE_FOLDING}  Unicode 12.1.0 CaseFolding.txt\n"
    )
    if not unicode_manifest.is_file() or unicode_manifest.read_text(
        encoding="utf-8"
    ) != expected_unicode_record:
        errors.append("UNICODE_CASEFOLD.sha256: Unicode folding data hash is incorrect")

    license_text = (ROOT / "LICENSE").read_text(encoding="utf-8") if (ROOT / "LICENSE").is_file() else ""
    if "GNU AFFERO GENERAL PUBLIC LICENSE" not in license_text or "Version 3" not in license_text:
        errors.append("LICENSE: complete GNU AGPL version 3 text is missing")
    pubspec = (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
    if not re.search(r"^license:\s*AGPL-3\.0-or-later\s*$", pubspec, re.MULTILINE):
        errors.append("pubspec.yaml: license must be AGPL-3.0-or-later")

    for path in sorted((ROOT / "lib").rglob("*.dart")):
        text = path.read_text(encoding="utf-8")
        if not text.startswith("// SPDX-License-Identifier: AGPL-3.0-or-later\n"):
            errors.append(f"{path.relative_to(ROOT)}: AGPL SPDX header is missing")
        if "import 'dart:io'" in text or 'import "dart:io"' in text:
            errors.append(f"{path.relative_to(ROOT)}: VM-only dart:io import is forbidden")
    for directory in ("test", "tool"):
        for path in sorted((ROOT / directory).rglob("*.dart")):
            if not path.read_text(encoding="utf-8").startswith(
                "// SPDX-License-Identifier: AGPL-3.0-or-later\n"
            ):
                errors.append(f"{path.relative_to(ROOT)}: AGPL SPDX header is missing")
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
