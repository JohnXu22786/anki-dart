# Source and license notice

The SQLite connection pragmas in this adapter follow Anki Core's
`rslib/src/storage/sqlite.rs` at commit
`e64c6b1aee3e8d668fb8bbe084beada8e070d985`. The card query and mutation SQL
and row conversions adapt `rslib/src/storage/card/mod.rs`,
`rslib/src/storage/card/get_card.sql`, `rslib/src/storage/card/data.rs`,
`rslib/src/storage/card/update_card.sql`,
`rslib/src/storage/card/add_card.sql`,
`rslib/src/storage/card/add_card_if_unique.sql`,
`rslib/src/storage/card/add_or_update.sql`,
`rslib/src/storage/note/mod.rs`, `rslib/src/storage/note/get.sql`, and
`rslib/src/storage/note/get_without_fields.sql` at the same commit; their
SHA-256 digests are recorded in `SOURCE.sha256`. The adapter reuses the shared
`anki_backend_models` package for Card and Note values. Behavior is compared
against the repository's AnkiDroid 2.25.3 baseline at commit
`d9bf072f814a0c37d30a694192593b31ff2df875`. Schema and migration SQL remain in
the separately licensed `anki_collection_schema` package.

The collection connection also registers Core's deterministic
`field_at_index(flds, index)` SQLite function from `rslib/src/storage/sqlite.rs`
for first-field note lookup. Other Core SQLite functions and collations remain
outside this adapter until their own source-derived units are completed.

The Dart adapter and tests are Copyright (C) 2026 John Tsui and distributed
under AGPL-3.0-or-later. SQLite bindings are provided by the independently
licensed `sqlite3` package (MIT). See this package's `LICENSE` file for the
complete AGPL license text. The repository's root `COPYING` file is unchanged.
