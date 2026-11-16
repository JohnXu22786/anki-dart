# Source and license notice

This package exposes the collection schema and its ordered migration SQL and
source callback contracts from Anki Core at commit
`e64c6b1aee3e8d668fb8bbe084beada8e070d985` of
[ankitects/anki](https://github.com/ankitects/anki). The exact SQL sources are
listed in `SOURCE.sha256` and preserved as test fixtures under
`test/fixtures/upstream/`. The migration callback names and source order are
adapted from `rslib/src/storage/upgrades/mod.rs`,
`rslib/src/storage/sqlite.rs`, and the storage modules listed in the hash
manifest. Initial metadata and defaults are adapted from the schema-11 config,
scheduler timing, deck, deck config, notetype, and collection config sources
listed there. Upstream is Copyright Ankitects Pty Ltd and contributors and licensed
under the GNU Affero General Public License, version 3 or later.

The Dart API and tests are Copyright (C) 2026 John Tsui and distributed under
AGPL-3.0-or-later. The package implements platform-neutral transactional
execution of the catalogued plans and the collection open/create sequence. It
does not provide a database driver, close/checkpoint a collection, configure
WAL, implement table CRUD, undo, or schema migration transformations. The
SQLite package supplies source-compatible first-create callbacks; a host
supplies localized text, migration callbacks, clock/timezone, and random
identifier sources.

Run `python3 tool/verify_source.py /path/to/anki-core` from this package to
verify all recorded source hashes against a checkout at the pinned commit.
