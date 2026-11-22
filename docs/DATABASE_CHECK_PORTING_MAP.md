<!-- SPDX-License-Identifier: AGPL-3.0-or-later -->
<!-- Copyright (C) 2026 John Tsui -->

# Database check porting map

This document records the pinned Anki Core repair contract for Unit68. The
progress and result presentation map the AnkiDroid UI branches; the shared
SQLite storage operation implements the pinned Core repair contract below.

## Pinned behavior

Sources: Anki Core `rslib/src/dbcheck.rs` at
`e64c6b1aee3e8d668fb8bbe084beada8e070d985`, and AnkiDroid
`AnkiDroid/src/main/java/com/ichi2/anki/DatabaseCheck.kt` at
`d9bf072f814a0c37d30a694192593b31ff2df875`.

Core's `check_database()` has three outer steps, in order:

1. Emit `Integrity`; run SQLite quick check; return a localized corruption
   error immediately if it is not clean.
2. Emit `Optimize`; run `VACUUM`, `REINDEX`, and `ANALYZE`.
3. Run repairs in one no-undo transaction. A failure in a repair must not
   return a success result.

The repair transaction emits `Cards`, checks card properties and removes cards
whose notes are missing; repairs missing deck IDs and invalid filtered-card
state; emits `Notes { current: 0, total }` and processes notes by notetype,
incrementing progress per note; then emits `History` and repairs revlogs,
missing deck names, the next new-card position, and invalid IDs. The full
source-derived sequence and result counters are in `CheckDatabaseOutput` and
`check_database_inner()`.

Per-note behavior includes restoring missing notetypes, preserving the
collection's tag expansion state, repairing invalid UTF-8, duplicate card
ordinals, cards without templates, field counts, future modification times,
and regenerating missing cards through note updates. Empty collections must
retain at least one notetype. These operations are coupled: a partial port must
not report successful completion while omitting them.

The AnkiDroid host runs the operation through its catching async task, projects
the generated progress event, and shows ordered problem strings or the
localized rebuilt message. Its progress UI uses no cancellation callback.

## Current Dart boundary

`CollectionSqliteStorage.checkDatabase()` performs integrity and optimization,
then transactionally repairs card due/interval/ordinal values, orphan cards,
missing deck IDs and parent names, invalid filtered-card state, note field
counts and future modification times, duplicate card ordinals, cards without
normal templates, revlog properties, the next new-card position, and invalid
IDs. It emits live note-loop progress and returns only after every pinned Core
repair category completes. The database operation includes invalid UTF-8
repair, card regeneration, and expanded-tag state preservation. The Deck Picker
exposes the check through the collection repository, shows live progress, and
presents localized repair, corruption, and failure dialogs. The deck list
refreshes after completion. `CollectionService.CheckDatabase` is generated
protocol code only; the app opens and uses `CollectionSqliteStorage` directly.
The progress flow is non-cancelable, matching AnkiDroid. Async task supervision
and native lifecycle integration remain host-side; app localization currently
supports English only.

## Porting constraints

- Put repairs in the existing shared SQLite collection package and expose a
  real storage operation; do not return success from a callback-only adapter.
- Keep Core repair order and the single repair transaction. Quick-check and
  optimization remain before it, matching Core.
- Preserve note/card content and 64-bit IDs; only remove or rewrite rows when
  the corresponding Core repair does so.
- Surface real progress from the repair loops and only show the completion
  result after the transaction commits.
- Exercise the same shared operation with native and Web collection drivers.
