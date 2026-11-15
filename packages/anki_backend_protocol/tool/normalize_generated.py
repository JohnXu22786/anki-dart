#!/usr/bin/env python3
# SPDX-License-Identifier: AGPL-3.0-or-later
"""Apply whitespace-only normalization to protoc_plugin output."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

for path in sorted((ROOT / "lib" / "anki").glob("*.dart")):
    source = path.read_text(encoding="utf-8")
    lines = source.splitlines()
    while lines and not lines[-1]:
        lines.pop()
    normalized = "\n".join(line.rstrip(" \t") for line in lines) + "\n"
    if normalized != source:
        path.write_text(normalized, encoding="utf-8")
