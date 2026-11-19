# Cross-platform Card Browser gap ledger

The Flutter Card Browser is shared across Android, iOS, Web, Windows, macOS,
and Linux. Collection queries and preference behavior live in shared Dart;
platform adapters provide storage and presentation.

## Implemented through Unit 44

- Cards/Notes mode loads and saves through the active collection's
  `browserTableShowNotesMode` config. Cards remains the default.
- Cards and Notes columns and sort settings persist independently using
  AnkiDroid's `activeCols`, `activeNoteCols`, `sortType`, `sortBackwards`,
  `noteSortType`, and `browserNoteSortBackwards` keys.
- Notes search uses the shared SQL compiler's Notes result type, selected-deck
  scoping, backend ordering, and 64-bit-safe Note IDs.
- Rows load their referenced note types, fields, and templates in batched
  storage queries. The note type column shows its exact name. Cards mode shows
  the selected card's template name (with the one-based Cloze index); Notes
  mode shows the card count.
- The sort-field column reads the configured notetype field index and applies
  Core's `html_to_text_line(..., true)` behavior. Notes rows also render tags
  and the sole-deck name or distinct-deck count.
- Question and Answer columns render the selected card using Core-compatible
  templates, field replacement, and text-line conversion.
- Saved searches work in either mode. Selection and navigation preserve the
  current row identity. Unit 33 adds existing-note field editing, and Unit 36
  exposes its note-update undo action in the shared Card Browser menu. Unit 44
  connects suspend, bury, and delete to the active collection and provides
  undo/redo actions for those bulk operations; preview and other browser
  operations remain scoped to their documented capabilities.

## Unit 23 — Core row values and metadata

- Cards mode reads one selected Card; Notes mode reads all cards for the Note.
  Due selection excludes filtered, new, suspended, and buried cards in Notes
  mode and applies Core's filtered/new/learning/review labels and negative queue
  parentheses in Cards mode.
- Ease and interval retain Core's card-type filtering, integer division, and
  rounding; lapses and reviews aggregate all row cards. Creation time uses the
  Note ID's millisecond timestamp, modification columns use persisted seconds,
  and original position falls back to the due position for new cards.
- FSRS stability, normalized difficulty, and retrievability use persisted
  memory state, last review time and card decay, with Core's default decay.
  Missing memory state remains empty. When inferring an absent last-review
  time, learning-queue due timestamps take precedence over day-based due
  interpretation, matching Core's `due_time()` ordering.
- Row snapshots retain template font, size, per-cell RTL/elision, and
  color/flag metadata from Core. The pinned AnkiDroid 2.25.3
  `BrowserMultiColumnAdapter` consumes row color but ignores font, RTL, and
  elision fields; it uses end truncation for cells. Flutter keeps those metadata
  values in the shared row model but does not apply them to visible text in this
  unit, preserving the pinned Android adapter's rendering boundary.
- A Notes-mode search can return a persisted Note with no Cards (for example,
  a whole-collection note-only query when no deck is selected). Core's
  `RowContext::new()` returns `DatabaseCheckRequired` for this row. Flutter
  preserves it as a typed row error, displays Core's English message in every
  cell, uses the unknown/default row color, and strikes through and visually
  unchecks the row. It retains the normal row listeners and does not clear a
  selected ID from the selection model if that row later becomes an error; this
  matches the pinned AnkiDroid adapter's existing behavior.
- Scheduler timing comes from collection creation/rollover settings and the
  active local timezone through the shared storage adapter. Dates use Core's
  local `YYYY-MM-DD` and `YYYY-MM-DD @ HH:mm` forms. English timespans use
  Core's unit selection and rounding boundaries through the app ARB. No other
  language catalog is currently shipped; non-English plural forms remain a
  localization follow-up.
- Source pins, licenses, and SHA-256 hashes are recorded in
  `apps/anki/ANKIDROID_SOURCE.sha256` and `ANKIDROID_UPSTREAM.md`.

## Unit 24 — Search history and structured filters

- Search requests now carry query text and structured tags, flags, and card
  states together into the active collection search. Structured categories
  retain their OR grouping, combine with the query and other categories using
  AND, and remain scoped to the selected deck.
- Recent searches persist through shared preferences using the source-derived
  history JSON contract. New non-empty searches move to the front, equal
  entries are promoted, history is capped at 30 entries, and a blank unfiltered
  search does not add an entry. History can be edited into the search box,
  submitted, removed, cleared, expanded beyond five visible items, and restored
  with deck and note-type IDs resolved against the active collection.
- Unresolved stored deck or note-type IDs restore the query with empty
  structured filters, matching the source contract. The filter editor exposes
  active-collection deck, note-type, and tag choices, plus flags and card
  states. History entries retain their stored filter values so searches with
  the same query and different filters remain distinguishable. Unit 31 wires
  the shared canonical writer into history row titles.
- The shared implementation applies on Android, iOS, Web, Windows, macOS, and
  Linux. Shared preference storage is provided by `SharedPreferencesAsync`.
- Source pins and adaptation boundaries are recorded in
  `ANKIDROID_UPSTREAM.md` and `apps/anki/ANKIDROID_SOURCE.sha256`.

## Unit 31 — canonical search-history display

- The collection-backed history display resolves all stored deck and note-type
  IDs against the active collection's current name maps once per refresh, then
  uses shared `browserSearchString()` to produce the full canonical query for
  each row. This keeps persisted history IDs and identity unchanged while
  reflecting renamed collection items.
- Canonical rows show filter-only entries as their actual query and omit the
  old duplicate ID/filter summaries. Query-only entries use the same canonical
  writer; malformed queries or unavailable name maps fall back to the exact
  stored query. Missing deck or note-type IDs retain the shared restore
  contract and fall back to the raw query; raw filter summaries remain visible
  only when canonical projection is unavailable.
- The shared Flutter implementation applies on Android, iOS, Web, Windows,
  macOS, and Linux. The source pins, hashes, and license boundaries remain in
  `apps/anki/ANKIDROID_SOURCE.sha256` and `ANKIDROID_UPSTREAM.md`.

## Unit 32 — collection-backed Card Browser preview

- The Cards and Notes browser action now opens a shared Flutter preview screen.
  The collection loader uses the active profile, preserves result order and
  selected-row order, applies the source's single-row versus multi-row card
  selection behavior, and keeps IDs exact as `BigInt` through Web payload
  selection.
- Question and answer templates are rendered with Core's
  `BrowserCardTemplateRenderer` and displayed as static HTML through
  `flutter_html`'s Flutter widget renderer. The screen provides answer flip,
  previous/next, one-based progress and slider controls, back-side-only mode,
  keyboard navigation, and accessible control labels. Progress and slider are
  hidden for one-card results.
- Empty results, stale IDs, missing cards/notes/templates, renderer failures,
  and collection read errors surface a localized retry state. The preview
  loader remains injectable for tests and alternate hosts.
- The renderer dependency is MIT licensed; its resolved transitive notices
  are retained in `LICENSES/`. The HTML parser is pinned to 0.15.5 because
  flutter_html 3.0.0 uses an internal selector API removed in 0.15.7. Static
  HTML uses the shared Flutter surface on Android, iOS, Web, Windows, macOS,
  and Linux.
- Mark/flag/edit actions, reviewer actions, audio playback, and full
  JavaScript/media parity remain follow-up work. Source hashes, attribution,
  and source mappings are in `apps/anki/ANKIDROID_SOURCE.sha256`,
  `ANKIDROID_UPSTREAM.md`, and `NOTICE.md`.

## Unit 26 — mode-aware sort choices

- The sort chooser groups active sortable columns in active-column order, then
  hidden sortable and unavailable columns in source order. Choices use the
  current Cards or Notes mode and include selected-direction explanations and
  source-specific unavailable reasons. Labels preserve host projections for
  active columns and use localized column names for hidden columns.
- Sort validation shares the mode availability mapping with the collection
  controller and SearchSql compiler. Invalid persisted sort keys fall back to
  no ordering, unsupported selections are rejected before saving, and
  timing-based sorts receive collection timing.
- The source mapping is pinned in `apps/anki/ANKIDROID_SOURCE.sha256`; behavior
  and license boundaries are recorded in `ANKIDROID_UPSTREAM.md`.

## Unit 33 — existing-note field editing

- Card Browser edit opens one shared Flutter screen on all six targets. Cards
  mode resolves the selected Card to its Note; Notes mode resolves the Note's
  Cards in template order. Browser IDs remain exact signed 64-bit values, and
  a missing row, note, collection, or matching note type shows a localized
  recoverable load error.
- The editor displays current values under notetype field names in stored
  order. Save reloads the existing Note and its exact matching Notetype,
  replaces only the fields, applies Core's `Note.prepare_for_update()` field
  count and normalization behavior using the collection's normalization
  setting, then persists through `CollectionSqliteStorage.updateExistingNote()`.
  Failed saves retain the editor and values for correction or retry. Returning
  to the browser refreshes its current search while retaining its selection.
- The collection operation runs in a SQLite savepoint, sets local note
  modification metadata, generates newly required normal/Cloze cards, and
  records bounded in-memory undo/redo for note updates. Unit 36 exposes an
  accessible, localized note-update undo action from the Card Browser collection
  menu. This remains scoped to note updates and does not implement Core's
  generic collection undo journal. Unit 44 adds separate undo/redo access for
  Card Browser bulk suspend, bury, and delete operations. New-note creation,
  media, image occlusion, add-ons, note-type and template editing, and
  Android-only editor affordances remain follow-up work.
- Source pins, hashes, attribution, and adaptation boundaries are recorded in
  `apps/anki/ANKIDROID_SOURCE.sha256` and `ANKIDROID_UPSTREAM.md`.

## Unit 36 — collection undo after note edits

- After an existing-note save, the Card Browser shows a localized, accessible
  undo menu action when the bounded note-update history reports it available.
  The action disappears or refreshes after save, undo, collection changes,
  history invalidation, and failed mode changes; successful replay refreshes
  the visible browser results. Replay errors use the existing localized browser
  action error.
- This is the pinned source's collection-level undo placement. It does not add
  undo or redo controls to the editor, expose redo from the Card Browser, or
  claim that unrelated collection operations can be undone. The shared Flutter
  surface applies the same behavior on Android, iOS, Web, Windows, macOS, and
  Linux.
- The source mapping and license boundary are recorded in
  `ANKIDROID_UPSTREAM.md`.

## Unit 37 — existing-note tag editing

- The shared existing-note editor loads the note's selected tags and known
  tags from the active collection. The localized, accessible chooser supports
  case-insensitive hierarchical ordering, search/filter, select/remove, and
  adding tags; confirming applies its selection and cancel leaves editor state
  unchanged. Normalized duplicates are rejected in the chooser, and the
  collection update remains responsible for Core-compatible tag cleanup,
  canonicalization, registration and history.
- Field and tag changes save together through
  `CollectionSqliteStorage.updateExistingNote()`. Tag-only changes participate
  in Unit 35 undo, unchanged selection avoids a collection update, and
  field-only edits preserve the note's tags. Save failures retain entered
  values for retry. Returning to Card Browser refreshes results and retains
  selection. Shared behavior applies on Android, iOS, Web, Windows, macOS and
  Linux.
- The pinned AnkiDroid 2.25.3 behavior is in
  `AnkiDroid/src/main/java/com/ichi2/anki/NoteEditorFragment.kt:624–850,1259–1337`,
  `AnkiDroid/src/main/java/com/ichi2/anki/dialogs/tags/TagsDialog.kt`,
  `AnkiDroid/src/main/java/com/ichi2/anki/dialogs/tags/TagsDialogViewModel.kt`,
  `AnkiDroid/src/main/java/com/ichi2/anki/dialogs/tags/TagsArrayAdapter.kt`,
  and `AnkiDroid/src/main/java/com/ichi2/anki/dialogs/tags/TagsList.kt`.
  Multi-note indeterminate states,
  card-state filtering, new-note tags, media, image occlusion, add-ons,
  note-type/template editing, generic collection undo and Android-only
  affordances remain outside this slice. Exact paths and semantics are in
  `ANKIDROID_UPSTREAM.md`; no upstream source or resource was copied.

## Remaining migration work

- Exercise black/e-ink palette and focused-pane rendering in a host once those
  theme modes and pane-current state are exposed by the Flutter app.
- Preview now covers collection-backed static question/answer content;
  reviewer actions, audio playback, full JavaScript/media rendering parity,
  and bulk actions remain open.
- Migrate and track unresolved upstream Card Browser TODO coverage.
- Verify each platform's storage and presentation adapters in its native
  runtime; the shared Flutter implementation has no platform-specific browser
  logic.

## Unit 29 — source-matched semantic row theme colors

- The shared `CardBrowserRowColor` resolver maps default/unknown, marked,
  suspended, buried, and all seven flags to AnkiDroid 2.25.3's pinned light and
  dark resources. Explicit black and e-ink palettes project their corresponding
  source values for hosts that configure those modes.
- A focused pane row takes precedence over backend color. Backend errors use
  the theme background, remain unchecked, and retain strike-through rendering.
  Multi-select changes selection state and checkbox only; it preserves the row
  color. The `InkWell` continues to provide Flutter's pressed feedback.
- Semantic row backgrounds retain the exact source values. Row text chooses
  black or white to keep at least 4.5:1 contrast against those backgrounds.
- The current Flutter app selects light/dark from brightness and has no black,
  e-ink, or pane-current theme state. The shared mapping supports explicit
  black/e-ink palette configuration and focused-row precedence, but the host
  must provide those values to render them in an active screen.
- Pinned source hashes, license attribution, and adaptation boundaries are in
  `apps/anki/ANKIDROID_SOURCE.sha256` and `ANKIDROID_UPSTREAM.md`.
