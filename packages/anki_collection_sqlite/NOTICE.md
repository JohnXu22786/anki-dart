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

New-card candidates adapt Anki Core's `rslib/src/storage/card/new_cards.sql`,
`for_each_new_card_in_deck()`, and
`for_each_new_card_in_active_decks()`, plus `NewCardSorting::write()` in
`rslib/src/storage/card/mod.rs`, at commit
`e64c6b1aee3e8d668fb8bbe084beada8e070d985`. The caller supplies either one
exact deck ID or an explicit active-deck ID set, a gather sort mode, and (for
random modes) an unsigned 32-bit salt. The query returns Core's six candidate
fields, preserves signed 64-bit IDs and mtime, validates template ordinal as
u32, and leaves SQLite ordering intact. Active-deck IDs are exact typed
integers rendered as decimal SQL literals, avoiding SQLite's bind-variable
limit. Source hashes are recorded in `SOURCE.sha256`; this is an independent
adaptation and copies no upstream SQL or Rust code. Active-deck derivation,
gather-priority, limits, post-gather sorting, queue composition and scheduler
execution remain outside this unit. Root `COPYING` is unchanged.

Intraday learning candidates adapt Anki Core's
`rslib/src/storage/card/intraday_due.sql` and
`for_each_intraday_card_in_active_decks()` in `rslib/src/storage/card/mod.rs`
at the same pinned revision. The query accepts active deck IDs and a learning
cutoff from its caller and returns the source seven-column projection. Card,
note, and deck IDs and mtime remain exact signed 64-bit values; due and reps
use Core's i32 and u32 representations, including its default-zero conversion
for an unreadable due value. It does not copy upstream SQL or Rust code. The
SQL source hash is recorded in `SOURCE.sha256`. This adapter code and its tests
are licensed under AGPL-3.0-or-later; root `COPYING` remains unchanged.

Review and interday-learning candidates adapt Anki Core's
`rslib/src/storage/card/due_cards.sql`,
`for_each_due_card_in_active_decks()`, and `review_order_sql()` in
`rslib/src/storage/card/mod.rs` at the same pinned revision. The caller supplies
ordered active deck IDs, queue kind, review order, FSRS state, and all scheduler
timing values. The query returns the eight Core candidate fields, keeps signed
64-bit IDs and mtime exact, converts due with Core's i32/default-zero behavior,
and validates reps as u32. It preserves supplied deck ordering for Deck sorts,
uses Core's FSRS and non-FSRS expressions, and appends `fnvhash(id, mod)` as a
deterministic tie-breaker. Duplicate deck IDs are removed without changing
first-seen rank, and typed decimal literals avoid SQLite's bind-variable limit.
It does not derive active decks, inspect collection configuration, or execute
scheduler admission, mixing, counts, load-balancing, persistence, or UI. Source
hashes are pinned in `SOURCE.sha256`; this independent adaptation is licensed
under AGPL-3.0-or-later, and root `COPYING` remains unchanged.

`getAllCardsDueInRange()` adapts `SqliteStorage::get_all_cards_due_in_range()`
from `rslib/src/storage/card/mod.rs` at the same pinned revision. It selects
the source four-field card projection for the caller's half-open due-day range,
then groups rows into one bucket per day without changing SQLite query order.
Bounds follow Core's u32 types; the range is capped at the caller's Core
99-day `LOAD_BALANCE_DAYS` window to keep bucket allocation bounded. All queue
and deck states are included, and identifiers retain signed 64-bit precision.
The source file hash is already recorded in `SOURCE.sha256`; this original Dart
implementation and its tests are covered by the package's AGPL license. Root
`COPYING` remains unchanged.

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

`removeDeckAndChildren()` follows the pinned Core deck removal and undo paths
in `rslib/src/decks/remove.rs`, `rslib/src/decks/undo.rs`, and
`rslib/src/config/deck.rs`; filtered-deck queue restoration follows
`rslib/src/scheduler/filtered/card.rs`. The source hashes are listed in
`SOURCE.sha256` and validated by `tool/check_package.py`. The shared adapter
does not copy Core source.

`unburyDeck()` follows `rslib/src/scheduler/bury_and_suspend.rs` and restores
learning queues using `rslib/src/scheduler/filtered/card.rs`. It keeps the
selected deck and descendant scope, Core's buried-queue filter, card type/due
queue mapping, and undoable collection transaction. These source hashes are
validated by the same package checker; no upstream implementation is copied.

`emptyFilteredDeck()` follows Core's `empty_filtered_deck()` operation in
`rslib/src/scheduler/filtered/mod.rs` and its service operation mapping in
`rslib/src/scheduler/service/mod.rs`. It enumerates cards only in the exact
filtered deck, restores home deck and original due values, restores the queue
from card type and due only for nonnegative queues, and clears filtered-deck
metadata. Each card update uses the collection's current modification time
and USN. The source hashes, including the shared queue-restoration helper in
`rslib/src/scheduler/filtered/card.rs`, are checked by `tool/check_package.py`;
no upstream source is copied.

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
The package combines note edits and collection operations in one bounded
30-entry in-memory undo journal. Note steps replay the note, generated-card,
tag, `nextPos` config, and collection-time changes. Undoable collection
transactions capture SQLite changesets for primary-key tables and expose
Core-derived row categories and mutation variants for card, note, deck, deck
config, tag, revlog, config, collection, notetype, and custom rows. Captured
changesets provide inverses for operations without an explicit host callback;
existing callbacks remain the complete inverse where operations also change
non-SQL state. Deck deletion records card, note, and deck grave variants for
Core's keyless graves table. Custom restore points merge newer undo steps into
their named target.
Successive same-note updates coalesce within Core's 60-second window when they
only change the note and collection-modification rows. Operations with no
tracked SQL changes preserve their caller's inverse callbacks and optional
label. Writes through adapter mutation methods clear this journal; direct
substore writes and enclosing transactions must call
`discardExistingNoteUpdateUndoHistory()`. Core's queue answer/answer-undo
variants are Scheduler/review-session behavior and are not claimed by this
unit. Reviewer feedback remains a projection until the later unit adds its UI
call site. The app exposes localized labeled collection actions in the Card
Browser and Deck Picker, including normal-deck creation and rename.

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

Deck creation behavior is independently implemented from Anki Core
`rslib/src/decks/mod.rs`, `rslib/src/decks/name.rs`, and
`rslib/src/decks/addupdate.rs`, pinned to
`e64c6b1aee3e8d668fb8bbe084beada8e070d985`. The adapter preserves normalized
name composition, collision checks, filtered-ancestor rejection, and Core-style
undo/redo for newly created deck rows. These sources are GNU AGPL-3.0-or-later;
no upstream source was copied. Exact source hashes are recorded in
`SOURCE.sha256`; root `COPYING` remains unchanged.

The in-memory Notes and Cards text export follows Anki Core's
`rslib/src/import_export/text/csv/export.rs`,
`rslib/src/import_export/service.rs`, `proto/anki/import_export.proto`, and
`rslib/src/text.rs` at commit `e64c6b1aee3e8d668fb8bbe084beada8e070d985`.
The implementation generates TSV headers and records and selects notes/cards
from the collection; it uses the shared model package for card rendering.
Exact source hashes are checked by `tool/check_package.py` and recorded in
`SOURCE.sha256`. The adapter is AGPL-3.0-or-later; root `COPYING` is unchanged.

The portable collection snapshot and media boundary is original Dart code
licensed under AGPL-3.0-or-later. Native snapshots call the public online
backup API from the independently licensed `sqlite3` Dart package (MIT); no
SQLite package source is copied or modified. Web snapshots use SQLite's public
`VACUUM INTO` SQL command and the package's publicly exported
`InMemoryFileSystem`, then remove its temporary in-memory file after copying
the bytes. The Web media adapter uses public browser IndexedDB APIs and stores
media values as Blobs in its own host-named database; reads use Blob slices to
stream bounded chunks.

`src/apkg_package_builder.dart` writes the ZIP container and APKG package
metadata in Dart. It uses `archive` 4.7.1 (MIT) for ZIP encoding,
`crypto` 3.0.8 (BSD-3-Clause) for media SHA-1 values, and a portable Dart
encoder in `src/zstd_frame.dart` for valid raw-block Zstandard frames. The
`pure_zstd` 1.1.0 MIT package is used only by tests to decode and verify those
frames. The exporter uses `html` 0.15.7 (MIT) to decode HTML entities for
media filenames and LaTeX hashes; `csslib` 1.0.2 (BSD-3-Clause) is its
transitive dependency. Third-party license texts are retained under
`LICENSES/`. The package names and metadata are defined by the pinned Anki
Core protocol; no Core implementation code is copied.

The shared APKG exporter follows the implementation and data rules in Anki
Core `rslib/src/import_export/package/apkg/export.rs`,
`rslib/src/import_export/gather.rs`,
`rslib/src/import_export/package/media.rs`,
`rslib/src/scheduler/new.rs`, `rslib/src/scheduler/filtered/card.rs`,
`rslib/src/storage/card/data.rs`, `rslib/src/latex.rs`,
`rslib/src/notetype/mod.rs`, and `rslib/src/text.rs`, pinned to
`e64c6b1aee3e8d668fb8bbe084beada8e070d985`. The implementation is original
Dart code; the pinned source hashes are recorded in `SOURCE.sha256` and
validated by `tool/check_package.py`. It uses host-provided detached SQLite
copies and portable media reads, so shared export code does not depend on
`dart:io`.

`CollectionSqliteStorage.buildLoadBalancerCache()` adapts the storage-backed
setup in Core `LoadBalancer::new()` from
`rslib/src/scheduler/states/load_balancer.rs`. It reads the existing due-card
history query for the caller's 99-day range, loads all stored deck configs, and
delegates per-preset grouping to `LoadBalancerCache.fromHistory()`. The caller
provides the collection day and may provide the deck-to-config map directly.
The collection convenience entry point derives the map using Core
`Deck::config_id()` from `rslib/src/decks/mod.rs`: it includes every normal
deck's config ID, including IDs without a matching config row, and omits
filtered decks. Cards whose deck has no mapping are skipped during history
grouping. This adapter does not derive scheduler timing or execute a scheduler.
Both deck-model and load-balancer source hashes are recorded in `SOURCE.sha256`
and validated by `tool/check_package.py`.

`CollectionSqliteStorage.reviewSchedulingContextWithCardLoadBalancerForNow()`
adapts the card/home-deck/config selection in Core's
`Collection::get_scheduling_states()` from
`rslib/src/scheduler/answering/mod.rs`. It resolves the card's original deck
when present, uses the home deck's config ID, and selects the note for sibling
balancing only when that config enables `bury_reviews`. The missing-config
fallback follows Core's false default. The exact source file is pinned at
`e64c6b1aee3e8d668fb8bbe084beada8e070d985`; its SHA-256 is recorded in
`SOURCE.sha256` and validated by `tool/check_package.py`.
