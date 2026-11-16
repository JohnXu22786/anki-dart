#!/usr/bin/env python3
# SPDX-License-Identifier: AGPL-3.0-or-later
"""Check package licensing metadata and Dart source headers."""

from pathlib import Path
import hashlib
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
SOURCE_HASHES = {
    "rslib/src/storage/sqlite.rs": "877e18ef2ddcc497a91fca0c2a84d2f22658f09582d8c7f2ba1f03ca2d4ba73c",
    "rslib/src/text.rs": "2b60699e1c6ad478baf80bfa50a85e9772f40279400d62c84b071c72945b1762",
    "rslib/src/cloze.rs": "478a35d1248be262ed2d0941202ac8f201c7eb0a5c57b7198d3ace03898fd1c5",
    "rslib/src/storage/card/data.rs": "aacbb588af4cf902eeb54d15cecc37a35b410441d67839f48929fea9fd515a89",
    "Cargo.lock": "0974d73d25e2c835fe7efe336bd727f9095ea73029fd4ca6a3ee7d1cfc6042aa",
    "regex-syntax-0.8.6/src/unicode_tables/case_folding_simple.rs": "7622c7f7f03ac0dc2f2bcd51c81a217d64de0cc912f62f1add5f676603a02456",
    "regex-syntax-0.8.6/src/unicode_tables/property_values.rs": "ef9131ce0a575c7327ec6d466aafd8b7c25600d80c232b5a4110bbf0a5a59136",
    "regex-syntax-0.8.6/src/unicode_tables/property_names.rs": "8c93985d1bcb01735667a3c4cb92f7e260d267326bde9d7f048bc77cd7e07855",
    "lib/src/unicode_case_folding.dart": "b2ced23e7e9e64b8d05967232d2153d1976d9a0da764f67ce4bd85be869feb74",
    "lib/src/unicode_property_aliases.dart": "6eb765474bff5dbb4f3a1062243286f2f6ba43396186d13dfb16ce7e6657fd44",
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
        match = re.fullmatch(
            r"([0-9a-f]{64})  (rslib/src/[a-z0-9_/.]+\.(?:sql|rs)|Cargo\.lock|regex-syntax-[a-z0-9_.]+/src/[a-z0-9_/.]+\.rs|lib/src/[a-z0-9_/.]+\.dart)",
            line,
        )
        if not match:
            errors.append(f"SOURCE.sha256: invalid entry {line!r}")
            continue
        manifest[match.group(2)] = match.group(1)
    for source, digest in SOURCE_HASHES.items():
        if manifest.get(source) != digest:
            errors.append(
                f"SOURCE.sha256: Core source hash differs from the pinned source: {source}"
            )
    local_unicode_table = ROOT / "lib/src/unicode_case_folding.dart"
    local_unicode_digest = hashlib.sha256(local_unicode_table.read_bytes()).hexdigest()
    if local_unicode_digest != SOURCE_HASHES["lib/src/unicode_case_folding.dart"]:
        errors.append(
            "lib/src/unicode_case_folding.dart: content differs from the pinned generated table"
        )
    if manifest.get("lib/src/unicode_case_folding.dart") != local_unicode_digest:
        errors.append(
            "SOURCE.sha256: generated Unicode table hash does not match the local file"
        )
    local_alias_table = ROOT / "lib/src/unicode_property_aliases.dart"
    local_alias_digest = hashlib.sha256(local_alias_table.read_bytes()).hexdigest()
    if local_alias_digest != SOURCE_HASHES["lib/src/unicode_property_aliases.dart"]:
        errors.append(
            "lib/src/unicode_property_aliases.dart: content differs from the pinned generated table"
        )
    if manifest.get("lib/src/unicode_property_aliases.dart") != local_alias_digest:
        errors.append(
            "SOURCE.sha256: generated Unicode property alias hash does not match the local file"
        )
    if "Cargo.lock" in manifest and manifest["Cargo.lock"] != SOURCE_HASHES["Cargo.lock"]:
        errors.append("SOURCE.sha256: Core regex dependency lock hash differs from the pinned source")

    for directory in ("lib", "test", "tool"):
        for path in sorted((ROOT / directory).rglob("*.dart")):
            text = path.read_text(encoding="utf-8")
            expected_spdx = (
                "// SPDX-License-Identifier: Apache-2.0\n"
                if path.name in ("unicode_case_folding.dart", "unicode_property_aliases.dart")
                else "// SPDX-License-Identifier: AGPL-3.0-or-later\n"
            )
            if not text.startswith(expected_spdx):
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
