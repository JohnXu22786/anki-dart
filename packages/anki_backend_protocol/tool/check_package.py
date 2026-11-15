#!/usr/bin/env python3
# SPDX-License-Identifier: AGPL-3.0-or-later
"""Validate source and generated-artifact provenance for this package."""

from hashlib import sha256
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
AGPL_SPDX = "AGPL-3.0-or-later"
SPDX_PATTERN = re.compile(
    r"^\s*(?://|/\*|\*)?\s*SPDX-License-Identifier:\s*([^\s*]+)\s*$",
    re.MULTILINE,
)
UPSTREAM_PROTO_LICENSE = (
    "// License: GNU AGPL, version 3 or later; "
    "http://www.gnu.org/licenses/agpl.html"
)
EXPECTED_SOURCE_COMMIT = "e64c6b1aee3e8d668fb8bbe084beada8e070d985"
EXPECTED_FILES = {
    "ankidroid.proto", "ankihub.proto", "ankiweb.proto", "backend.proto",
    "card_rendering.proto", "cards.proto", "collection.proto", "config.proto",
    "deck_config.proto", "decks.proto", "frontend.proto", "generic.proto",
    "github.proto", "i18n.proto", "image_occlusion.proto", "import_export.proto",
    "links.proto", "media.proto", "notes.proto", "notetypes.proto",
    "scheduler.proto", "search.proto", "stats.proto", "sync.proto", "tags.proto",
}


def generated_spdx_error(text: str) -> str | None:
    identifiers = SPDX_PATTERN.findall(text)
    if identifiers != [AGPL_SPDX]:
        return f"expected exactly one {AGPL_SPDX} SPDX tag, found {identifiers}"
    return None


def proto_license_error(text: str, source_spdx: str | None, source_name: str) -> str | None:
    if source_spdx != AGPL_SPDX:
        return f"source manifest must tag this schema {AGPL_SPDX}, found {source_spdx!r}"
    identifiers = SPDX_PATTERN.findall(text)
    if any(identifier != AGPL_SPDX for identifier in identifiers):
        return f"found non-AGPL SPDX identifiers {identifiers}"
    license_headers = [
        line for line in text.splitlines()[:10] if line.startswith("// License:")
    ]
    if license_headers and any(UPSTREAM_PROTO_LICENSE not in line for line in license_headers):
        return "conflicting upstream license header"
    if not license_headers and source_name != "ankidroid.proto":
        return "missing the pinned upstream AGPL license header"
    return None


def main() -> int:
    errors: list[str] = []
    schemas = ROOT / "proto" / "anki"
    actual_files = {path.name for path in schemas.glob("*.proto")}
    if actual_files != EXPECTED_FILES:
        errors.append(
            f"expected the 25 pinned .proto files; missing={sorted(EXPECTED_FILES - actual_files)}, "
            f"extra={sorted(actual_files - EXPECTED_FILES)}"
        )

    source_record = ROOT / "proto" / "SOURCE.sha256"
    recorded: dict[str, tuple[str, str]] = {}
    if source_record.is_file():
        for line in source_record.read_text(encoding="utf-8").splitlines():
            match = re.fullmatch(
                r"([0-9a-f]{64})  ([^ ]+)  anki/([a-z0-9_]+\.proto)", line
            )
            if not match:
                errors.append(f"proto/SOURCE.sha256: invalid entry {line!r}")
                continue
            digest, source_spdx, name = match.groups()
            if source_spdx != AGPL_SPDX:
                errors.append(f"proto/anki/{name}: source manifest has non-AGPL SPDX {source_spdx}")
            recorded[name] = (digest, source_spdx)
        if set(recorded) != EXPECTED_FILES:
            errors.append("proto/SOURCE.sha256: entries do not match the 25 schema files")
        for name, (digest, _) in recorded.items():
            path = schemas / name
            if path.is_file() and sha256(path.read_bytes()).hexdigest() != digest:
                errors.append(f"proto/anki/{name}: source digest does not match proto/SOURCE.sha256")
    else:
        errors.append("proto/SOURCE.sha256: source digest manifest is missing")

    notice = ROOT / "NOTICE.md"
    notice_text = notice.read_text(encoding="utf-8") if notice.is_file() else ""
    if EXPECTED_SOURCE_COMMIT not in notice_text:
        errors.append("NOTICE.md: pinned source commit is missing")
    if "Ankitects Pty Ltd" not in notice_text or "GNU Affero General Public License" not in notice_text:
        errors.append("NOTICE.md: upstream attribution or AGPL license notice is missing")

    license_file = ROOT / "LICENSE"
    license_text = license_file.read_text(encoding="utf-8") if license_file.is_file() else ""
    if "gnu affero general public license" not in license_text.lower() or "version 3" not in license_text.lower():
        errors.append("LICENSE: GNU AGPL version 3 text is missing")

    pubspec = (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
    if not re.search(r"^license:\s*AGPL-3\.0-or-later\s*$", pubspec, re.MULTILINE):
        errors.append("pubspec.yaml: package license must be AGPL-3.0-or-later")

    stems = {name.removesuffix(".proto") for name in EXPECTED_FILES}
    generated_root = ROOT / "lib" / "anki"
    expected_generated = {
        f"{stem}{suffix}.dart"
        for stem in stems
        for suffix in (".pb", ".pbenum", ".pbjson", ".pbserver")
    }
    actual_generated = {path.name for path in generated_root.glob("*.dart")}
    if actual_generated != expected_generated:
        errors.append(
            f"lib/anki: generated files do not match schema set; "
            f"missing={sorted(expected_generated - actual_generated)}, "
            f"extra={sorted(actual_generated - expected_generated)}"
        )
    for path in sorted(generated_root.glob("*.dart")):
        text = path.read_text(encoding="utf-8")
        license_error = generated_spdx_error(text)
        if license_error is not None:
            errors.append(f"{path.relative_to(ROOT)}: {license_error}")
        if "Generated code. Do not modify." not in text:
            errors.append(f"{path.relative_to(ROOT)}: missing generated-code marker")
        if "import 'dart:io'" in text or 'import "dart:io"' in text:
            errors.append(f"{path.relative_to(ROOT)}: generated protocol code imports dart:io")
        if any(line.endswith((" ", "\t")) for line in text.splitlines()):
            errors.append(f"{path.relative_to(ROOT)}: generated protocol code has trailing whitespace")
        if text.endswith("\n\n"):
            errors.append(f"{path.relative_to(ROOT)}: generated protocol code has extra blank lines at EOF")

    for path in sorted(schemas.glob("*.proto")):
        source_entry = recorded.get(path.name)
        source_spdx = source_entry[1] if source_entry is not None else None
        license_error = proto_license_error(path.read_text(encoding="utf-8"), source_spdx, path.name)
        if license_error is not None:
            errors.append(f"{path.relative_to(ROOT)}: {license_error}")

    barrel = ROOT / "lib" / "anki_backend_protocol.dart"
    if not barrel.is_file():
        errors.append("lib/anki_backend_protocol.dart: public barrel is missing")
    else:
        barrel_text = barrel.read_text(encoding="utf-8")
        if len(re.findall(r"^export 'anki/[a-z0-9_]+\.pbserver\.dart';$", barrel_text, re.MULTILINE)) != 25:
            errors.append("lib/anki_backend_protocol.dart: must export every generated service/message library")

    if errors:
        print("Protocol package validation failed:", file=sys.stderr)
        print("\n".join(f"- {error}" for error in errors), file=sys.stderr)
        return 1
    print("Validated 25 pinned schemas, AGPL provenance, generated outputs, and platform-neutral imports.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
