#!/usr/bin/env python3
# SPDX-License-Identifier: AGPL-3.0-or-later
"""Normalize pinned protoc_plugin output and add the package SPDX header."""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
AGPL_SPDX = "AGPL-3.0-or-later"
SPDX_LINE = f"// SPDX-License-Identifier: {AGPL_SPDX}"
SPDX_PATTERN = re.compile(
    r"^\s*(?://|/\*|\*)?\s*SPDX-License-Identifier:\s*([^\s*]+)\s*$",
    re.MULTILINE,
)


def normalize_source(source: str) -> str:
    identifiers = SPDX_PATTERN.findall(source)
    if identifiers and identifiers != [AGPL_SPDX]:
        raise ValueError(f"generated Dart has conflicting SPDX identifiers: {identifiers}")

    lines = source.splitlines()
    if not identifiers:
        lines.insert(0, SPDX_LINE)
    while lines and not lines[-1]:
        lines.pop()
    return "\n".join(line.rstrip(" \t") for line in lines) + "\n"


def normalize_generated_files() -> None:
    for path in sorted((ROOT / "lib" / "anki").glob("*.dart")):
        source = path.read_text(encoding="utf-8")
        normalized = normalize_source(source)
        if normalized != source:
            path.write_text(normalized, encoding="utf-8")


if __name__ == "__main__":
    normalize_generated_files()
