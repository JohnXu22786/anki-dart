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

The batch notetype loader adapts Core's `rslib/src/storage/notetype/mod.rs`,
`get_notetype.sql`, `get_fields.sql`, and `get_templates.sql` at the same
revision. Their SHA-256 digests are checked by `tool/check_package.py` and
recorded in `SOURCE.sha256`. It reuses the shared `anki_backend_models`
Notetype, NoteField, and CardTemplate values; this package's AGPL license and
complete `LICENSE` cover the Dart adapter.

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

The `updateExistingNote()` editor operation follows Core's
`rslib/src/notes/mod.rs`, `rslib/src/notetype/cardgen.rs`,
`rslib/src/notes/undo.rs`, `rslib/src/tags/register.rs`,
`rslib/src/config/notetype.rs`, `rslib/src/collection/transact.rs`,
`rslib/src/collection/timestamps.rs`, and
`rslib/src/storage/collection_timestamps.rs`, and
`rslib/src/storage/notetype/existing_cards.sql` at the pinned revision. It
preserves Core's no-op comparison, NFC preparation setting, tag canonical form,
last-deck/default fallback, existing-card preservation, per-template target
deck, new-card due policy, and collection modified timestamp. The minimal
`StdRng` random-position path is adapted from rand 0.9.4, rand_core 0.9.3, and
rand_chacha 0.9.0, the versions pinned by Core's `Cargo.lock`; those crates are
dual-licensed under Apache-2.0 or MIT. Only the seed-expansion, ChaCha12, and
bounded-u32 sampling algorithms needed by Core's `random_position()` are
implemented in `src/core_random_position.dart`. Pinned Core source hashes are
checked by `tool/check_package.py` and recorded in `SOURCE.sha256`.

The operation exposes an old-note and prior `col.mod` snapshot matching
`UndoableNoteChange::Updated` plus `UndoableCollectionChange::Modified` data,
along with newly registered tag names matching `UndoableTagChange::Added`.
The package records up to 30 in-memory undo steps and replays their note,
generated-card, tag, `nextPos` config, and collection-time changes. Successive
same-note updates coalesce within Core's 60-second window when they only change
the note and collection-modification rows. Writes through the adapter's async
mutation methods clear this scoped history; direct substore writes and enclosing
transactions must call `discardExistingNoteUpdateUndoHistory()`. This is
not yet a generic journal for other collection operations, and the application
does not yet present this history through an undo/redo affordance.

`CollectionSqliteStorage.addNoteToDeck()` maps Anki Core's new-note operation
from `rslib/src/notes/mod.rs`, `rslib/src/notetype/cardgen.rs`,
`rslib/src/notes/undo.rs`, `rslib/src/tags/register.rs`,
`rslib/src/config/{mod.rs,notetype.rs,deck.rs}`,
`rslib/src/collection/transact.rs`, `rslib/src/undo/changes.rs`,
`rslib/src/card/mod.rs`, and the note/card/config storage paths at
`e64c6b1aee3e8d668fb8bbe084beada8e070d985`. AnkiDroid's caller and validation
result boundary are `AnkiDroid/src/main/java/com/ichi2/anki/NoteEditorFragment.kt`
and `NoteFieldsCheckResult.kt` at
`d9bf072f814a0c37d30a694192593b31ff2df875`. The implementation uses existing
shared model/storage helpers and copies no upstream source. It is distributed
under AGPL-3.0-or-later; root `COPYING` remains unchanged. See
`docs/NOTE_ADD_GAP_REPORT.md` for supported behavior and host-owned validation.
