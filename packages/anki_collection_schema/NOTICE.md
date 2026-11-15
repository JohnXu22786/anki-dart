# Source and license notice

This package exposes the collection schema and its ordered migration SQL and
source callback contracts from Anki Core at commit
`e64c6b1aee3e8d668fb8bbe084beada8e070d985` of
[ankitects/anki](https://github.com/ankitects/anki). The exact SQL sources are
listed in `SOURCE.sha256` and preserved as test fixtures under
`test/fixtures/upstream/`. The migration callback names and source order are
adapted from `rslib/src/storage/upgrades/mod.rs`,
`rslib/src/storage/sqlite.rs`, and the storage modules listed in the hash
manifest. Upstream is Copyright Ankitects Pty Ltd and contributors and licensed
under the GNU Affero General Public License, version 3 or later.

The Dart API and tests are Copyright (C) 2026 John Tsui and distributed under
AGPL-3.0-or-later. This package does not implement a database driver, collection
opening/closing, transaction execution, or the named Rust transformations; an
adapter must implement and execute the callbacks in the catalog order.

Run `python3 tool/verify_source.py /path/to/anki-core` from this package to
verify all recorded source hashes against a checkout at the pinned commit.
