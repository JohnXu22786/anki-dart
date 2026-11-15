# Source and license notice

The SQLite connection pragmas in this adapter follow Anki Core's
`rslib/src/storage/sqlite.rs` at commit
`e64c6b1aee3e8d668fb8bbe084beada8e070d985`. Behavior is compared against the
repository's AnkiDroid 2.25.3 baseline at commit
`d9bf072f814a0c37d30a694192593b31ff2df875`. No upstream Rust implementation or
SQLite schema source is copied into this package. Schema and migration SQL
remain in the separately licensed `anki_collection_schema` package.

The Dart adapter and tests are Copyright (C) 2026 John Tsui and distributed
under AGPL-3.0-or-later. SQLite bindings are provided by the independently
licensed `sqlite3` package (MIT). See this package's `LICENSE` file for the
complete AGPL license text.
