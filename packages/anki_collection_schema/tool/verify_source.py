#!/usr/bin/env python3
"""Verify the Anki Core source hashes recorded by this package."""

from __future__ import annotations

import hashlib
import sys
from pathlib import Path


PACKAGE = Path(__file__).resolve().parent.parent
PINNED_COMMIT = "e64c6b1aee3e8d668fb8bbe084beada8e070d985"


def main() -> int:
    if len(sys.argv) != 2:
        print(f"usage: {Path(sys.argv[0]).name} /path/to/anki-core", file=sys.stderr)
        return 2
    source = Path(sys.argv[1]).resolve()
    if not (source / ".git").exists():
        print(f"not an Anki Core checkout: {source}", file=sys.stderr)
        return 2
    import subprocess

    commit = subprocess.run(
        ["git", "-C", str(source), "rev-parse", "HEAD"],
        check=True,
        capture_output=True,
        text=True,
    ).stdout.strip()
    if commit != PINNED_COMMIT:
        print(f"source commit mismatch: expected {PINNED_COMMIT}, got {commit}", file=sys.stderr)
        return 1
    failures = []
    for line in (PACKAGE / "SOURCE.sha256").read_text().splitlines():
        expected, relative = line.split("  ", 1)
        path = source / relative
        if not path.is_file():
            failures.append(f"missing: {relative}")
            continue
        actual = hashlib.sha256(path.read_bytes()).hexdigest()
        if actual != expected:
            failures.append(f"hash mismatch: {relative} ({actual})")
    if failures:
        print("\n".join(failures), file=sys.stderr)
        return 1
    print(f"verified {len((PACKAGE / 'SOURCE.sha256').read_text().splitlines())} sources at {commit}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
