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

The collection connection registers Core's deterministic
`field_at_index(flds, index)`, `process_text(text, flags)`, variadic
`fnvhash(i64...)`, card-data and FSRS extractors, and the `regexp`,
`regexp_fields`, and `regexp_tags` SQLite functions from `rslib/src/storage/sqlite.rs`.
The FSRS retrievability calculation also follows the pinned `fsrs` 5.2.0 crate
from `Cargo.lock` (crates.io checksum
`cab5f80c16d1d07e492a6828478ecb9f379f142ba6f19fa3b7955edd180ddc2e`). Its
BSD-3-Clause license and Open Spaced Repetition copyright notice are retained
in `LICENSES/fsrs-5.2.0-BSD-3-Clause.txt`; the source license SHA-256 is recorded
in `SOURCE.sha256`.
`process_text` adapts `without_combining` and `strip_clozes` from
`rslib/src/text.rs` and `rslib/src/cloze.rs`; `fnvhash` follows the pinned
`fnv` 1.0.7 hasher. Regex Unicode simple case-folding data is generated from
`regex-syntax` 0.8.6's `src/unicode_tables/case_folding_simple.rs` (Unicode
16.0.0; source SHA-256 is recorded in `SOURCE.sha256`). That crate's source is
available under Apache-2.0 or MIT; the generated table retains those notices
in its SPDX header. Unicode property aliases are generated from that crate's
`src/unicode_tables/property_names.rs` and `property_values.rs` tables; their
source SHA-256 digests are recorded in `SOURCE.sha256` and the generated table
has the same license notice. The `unicase` collation reuses the Unicode 12.1.0
case-fold data from `anki_backend_models`, generated from the pinned `unicase`
2.6.0 dependency. This adapter now covers the SQLite functions and collation
registered by pinned Core's collection opener.

`buildCoreDeckTree()` adapts `rslib/src/decks/tree.rs`,
`rslib/src/decks/limits.rs`, `rslib/src/decks/counts.rs`, and the due-count
query in `rslib/src/storage/deck/{mod.rs,due_counts.sql}`. It preserves
source-ordered hierarchy construction, the 99-level cap, malformed missing
parent handling, collapsed/filtered flags, default-deck hiding, and V3 daily
limit aggregation. Exact source SHA-256 values are recorded in `SOURCE.sha256`;
`deckTreeForNow()` resolves source timing-version, creation-offset, rollover,
learning-cutoff, deck-config-limit, and day-rollover unbury behavior from the
collection and platform clock.

The Dart adapter and tests are Copyright (C) 2026 John Tsui and distributed
under AGPL-3.0-or-later. SQLite bindings are provided by the independently
licensed `sqlite3` package (MIT). See this package's `LICENSE` file for the
complete AGPL license text. The repository's root `COPYING` file is unchanged.
