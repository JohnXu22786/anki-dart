#!/usr/bin/env python3
# SPDX-License-Identifier: AGPL-3.0-or-later
"""Check package AGPL metadata, pinned source records, and bundled SQL."""

from hashlib import sha256
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
SOURCE_COMMIT = "e64c6b1aee3e8d668fb8bbe084beada8e070d985"
SOURCE_HASHES = {
    "rslib/src/storage/schema11.sql": "e88e234221969efba452a83de8c415b1a7b7cffc93dc8f15e7de410749845d4f",
    "rslib/src/storage/upgrades/schema11_downgrade.sql": "7e64d73ffd81cc230131f7a35ebbbd1b579a5207f77a1be1283d166d6d6adfd9",
    "rslib/src/storage/upgrades/schema14_upgrade.sql": "072d867fd25bb35880d60f787798743385aa4fac783f59cb7ecb4f43ce5ebcb2",
    "rslib/src/storage/upgrades/schema15_upgrade.sql": "6fc6137df51b6d279b69d4bc887954d137bbc2ca36cb16fc3a9ae195ca1b4a36",
    "rslib/src/storage/upgrades/schema17_upgrade.sql": "1b19ef470568138987a6790d32d2a2e3b03cd5f6321a54ec3387239fd37da67a",
    "rslib/src/storage/upgrades/schema18_downgrade.sql": "4af1f8a6ea4425fe67a3c144ef0e96e1978f94214fe7009167bad44eec7b671d",
    "rslib/src/storage/upgrades/schema18_upgrade.sql": "32555b4193b9059c079b36320fa7aaee0e02415cc9cb88bcdedc1e5ac636a83b",
    "rslib/src/storage/upgrades/mod.rs": "b92e128df1944eb589654fca225b604fb3cab5e8157e1a80cd9e3f3063c45aa7",
    "rslib/src/storage/sqlite.rs": "877e18ef2ddcc497a91fca0c2a84d2f22658f09582d8c7f2ba1f03ca2d4ba73c",
    "rslib/src/storage/deckconfig/mod.rs": "74d1d0e0be58d68a6ebe0ae95acfd221f74cbc5ec80e4f391147e2047f6c5459",
    "rslib/src/storage/deck/mod.rs": "f55e715844e364b530b292d3a7e7dfddcad4abe9a81b778f788e1224932edc0d",
    "rslib/src/storage/notetype/mod.rs": "28aa0d31a150f00b04d38e301d472e0982dc40a572db751d9f1551d6ee5c16e0",
    "rslib/src/storage/config/mod.rs": "c69e1b376b9b6a5bbc1fc8fd8b4634806897524ceb9b34727dd2adec80a5bbeb",
    "rslib/src/storage/tag/mod.rs": "183e4143c2c09dcf6396db2a460d211052d0ab9417408c8a74e6a3b856cf68a2",
}


def main() -> int:
    errors: list[str] = []
    notice = (ROOT / "NOTICE.md").read_text(encoding="utf-8")
    for required in (SOURCE_COMMIT, "Ankitects Pty Ltd and contributors", "GNU Affero General Public License"):
        if required not in notice:
            errors.append(f"NOTICE.md: missing {required!r}")

    manifest: dict[str, str] = {}
    for line in (ROOT / "SOURCE.sha256").read_text(encoding="utf-8").splitlines():
        match = re.fullmatch(r"([0-9a-f]{64})  (rslib/src/[a-z0-9_/.]+\.(?:sql|rs))", line)
        if not match:
            errors.append(f"SOURCE.sha256: invalid entry {line!r}")
            continue
        manifest[match.group(2)] = match.group(1)
    if manifest != SOURCE_HASHES:
        errors.append("SOURCE.sha256: hashes do not match pinned Anki Core sources")

    license_text = (ROOT / "LICENSE").read_text(encoding="utf-8")
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
            errors.append(f"{path.relative_to(ROOT)}: platform-neutral library cannot import dart:io")
    for directory in ("test", "tool"):
        for path in sorted((ROOT / directory).rglob("*.dart")):
            if not path.read_text(encoding="utf-8").startswith(
                "// SPDX-License-Identifier: AGPL-3.0-or-later\n"
            ):
                errors.append(f"{path.relative_to(ROOT)}: AGPL SPDX header is missing")

    for source, digest in SOURCE_HASHES.items():
        if not source.endswith(".sql"):
            continue
        fixture = ROOT / "test" / "fixtures" / "upstream" / Path(source).name
        if not fixture.is_file() or sha256(fixture.read_bytes()).hexdigest() != digest:
            errors.append(f"test fixture does not match pinned SQL source: {source}")

    if errors:
        print("Collection schema package validation failed:", file=sys.stderr)
        print("\n".join(f"- {error}" for error in errors), file=sys.stderr)
        return 1
    print(f"Validated {len(SOURCE_HASHES)} pinned sources, AGPL metadata, fixtures, and Dart SPDX headers.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
