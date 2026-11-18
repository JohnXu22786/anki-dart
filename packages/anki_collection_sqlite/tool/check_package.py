#!/usr/bin/env python3
# SPDX-License-Identifier: AGPL-3.0-or-later
"""Check package licensing metadata and Dart source headers."""

from pathlib import Path
import hashlib
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
SOURCE_HASHES = {
    "rslib/src/notes/mod.rs": "5df79b58906206a87c5a28a06f886227df74e6a65d061d2cb915d35b34d35893",
    "rslib/src/notetype/cardgen.rs": "291408ba325c6573203abb3770f245a0307186b7a5a1c54d0eddeb763b5b0634",
    "rslib/src/notes/undo.rs": "2e3d4f5a74b6fef4b92922f7b9f18e69896bb60ff2860bcc5f6b224108ff802a",
    "rslib/src/tags/register.rs": "f1e3ff446b1f950d748c508eb0d93247c02e77274b0392bff4fa3c2fd53a943d",
    "rslib/src/tags/undo.rs": "7efcc570c49e2846f5eb530a14dd874abe6d7a9cea506ac6e7d50592d4668531",
    "rslib/src/config/notetype.rs": "fdfa2b331756b0b5ba20251a9c99addd668a5baad1d35c0183c1a0647d48b29b",
    "rslib/src/collection/transact.rs": "116b662bac90073ef04e40f43ff60e1546c0a5b6b0219466430aba1a31ae8be0",
    "rslib/src/collection/timestamps.rs": "daa5072f5e201b77038cdd574e7283fbea9f621f7f5c97d836796bb11807b9ac",
    "rslib/src/storage/collection_timestamps.rs": "1652457f868e36766c281f848b70bd619eeed31e32ccf8b3972083a4ff70de38",
    "rslib/src/decks/tree.rs": "0ab80ff9af9ebe7e9c06e6901e358f526ea938c2c315189c9528267c8c510b93",
    "rslib/src/decks/limits.rs": "d8de3c382f4f4e130699dd18bbc46b6a93664fc97ef8d45448479b4fb165af27",
    "rslib/src/decks/counts.rs": "6f2072a10af7c063eb98ebccca40395ee58ffd287d74061ab381645c4d36a01d",
    "rslib/src/storage/deck/mod.rs": "f55e715844e364b530b292d3a7e7dfddcad4abe9a81b778f788e1224932edc0d",
    "rslib/src/storage/deck/due_counts.sql": "31a67aed11f26fba9ed321f2b70486a70d83136dc5ffe887e3412da6c4492537",
    "rslib/src/scheduler/mod.rs": "0c147a58a2de9dd4e1f1dc199d0cf89b0e3d1e690bb70182d0ca91fd7e8fc0c1",
    "rslib/src/scheduler/bury_and_suspend.rs": "6e155f0368de174f8e57ac773e8ddd3846605982b7e2b3cf0c89a69ee15dbeb9",
    "rslib/src/scheduler/filtered/card.rs": "6aca7e9b55088f43d981eaafa8a02c5de538cf3c7e1c13640e3565de6ee4fd13",
    "rslib/src/config/mod.rs": "4d288b43ebfb365e083f2fcf352e6c6a87b973c0e8fea8aedcef872db8bd03eb",
    "rslib/src/decks/current.rs": "2b1f5b862986d2d34bd2e83d25ee970f4da6dc4cead2f71d9823744e88756051",
    "rslib/src/decks/mod.rs": "dc5a90c3465b7216b6ad1e42a0c44a2d18a99beea777023adcb63cb4abdf38d4",
    "rslib/src/decks/addupdate.rs": "724f8c20a37b54e05890be486d949fa932dd4aabaa0b9edd70ee9ad49c891fc2",
    "rslib/src/decks/name.rs": "0a4e33f5a92d2c479c4cbd59664b0de30a50a41453dbe131fc9c809f5afc5f4d",
    "rslib/src/storage/config/mod.rs": "c69e1b376b9b6a5bbc1fc8fd8b4634806897524ceb9b34727dd2adec80a5bbeb",
    "rslib/src/storage/config/add.sql": "3f7fb181b2e08b1e254e6b07df5438e4dc6a1b8d7a0d8dee4ebb2f134f25a81d",
    "rslib/src/storage/sqlite.rs": "877e18ef2ddcc497a91fca0c2a84d2f22658f09582d8c7f2ba1f03ca2d4ba73c",
    "rslib/src/storage/notetype/mod.rs": "28aa0d31a150f00b04d38e301d472e0982dc40a572db751d9f1551d6ee5c16e0",
    "rslib/src/storage/notetype/get_notetype.sql": "70bf01ceb8ff3001e75420b637d803e8acf6992200c29f2719f6976b10907f34",
    "rslib/src/storage/notetype/get_fields.sql": "473fcf61c0d32ab4e8d96294a20248e05cd7c13c1bb39aaa731b2cd16c129765",
    "rslib/src/storage/notetype/get_templates.sql": "ab91efa1af4740d8689e616413b08a10d3b5993601924cf5f9d832b03d79041e",
    "rslib/src/storage/notetype/existing_cards.sql": "16e4249a55c1480480fdd04df830a45e5c02d673613702b81b2d585209a41ddb",
    "rslib/src/text.rs": "2b60699e1c6ad478baf80bfa50a85e9772f40279400d62c84b071c72945b1762",
    "rslib/src/cloze.rs": "478a35d1248be262ed2d0941202ac8f201c7eb0a5c57b7198d3ace03898fd1c5",
    "rslib/src/storage/card/data.rs": "aacbb588af4cf902eeb54d15cecc37a35b410441d67839f48929fea9fd515a89",
    "Cargo.lock": "0974d73d25e2c835fe7efe336bd727f9095ea73029fd4ca6a3ee7d1cfc6042aa",
    "fsrs-5.2.0/LICENSE": "2604c7d519c6a579a7e24f09b218460b12d0d27da2eb0aa3fee09d5891511fa1",
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
    fsrs_license = (ROOT / "LICENSES/fsrs-5.2.0-BSD-3-Clause.txt").read_bytes()
    if hashlib.sha256(fsrs_license).hexdigest() != SOURCE_HASHES["fsrs-5.2.0/LICENSE"]:
        errors.append("fsrs BSD-3-Clause license differs from its pinned crate source")

    manifest = {}
    for line in (ROOT / "SOURCE.sha256").read_text(encoding="utf-8").splitlines():
        match = re.fullmatch(
            r"([0-9a-f]{64})  (rslib/src/[a-z0-9_/.]+\.(?:sql|rs)|Cargo\.lock|fsrs-[0-9.]+/LICENSE|regex-syntax-[a-z0-9_.]+/src/[a-z0-9_/.]+\.rs|lib/src/[a-z0-9_/.]+\.dart)",
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
