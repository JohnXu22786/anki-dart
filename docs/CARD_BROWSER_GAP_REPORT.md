# Cross-platform Card Browser gap ledger

The Flutter Card Browser is shared across Android, iOS, Web, Windows, macOS,
and Linux. Collection queries and preference behavior live in shared Dart;
platform adapters provide storage and presentation.

## Implemented through Unit 24

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
  current row identity; unsupported Note Editor, preview, and bulk operations
  continue to report their existing unavailable errors.

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
  states. History rows show stored filter values so searches with the same
  query and different filters remain distinguishable. The shared library now
  provides `browserSearchString()` to project requests to canonical Anki query
  text. Deck and note-type summaries still use persisted IDs because the app
  has not wired that projection into history row rendering; filter-only
  entries are titled “Filtered search”.
- The shared implementation applies on Android, iOS, Web, Windows, macOS, and
  Linux. Shared preference storage is provided by `SharedPreferencesAsync`.
- Source pins and adaptation boundaries are recorded in
  `ANKIDROID_UPSTREAM.md` and `apps/anki/ANKIDROID_SOURCE.sha256`.

## Remaining migration work

- Match Android's exact themed row colors and test row metadata in each native
  runtime. The Flutter app currently uses platform-neutral color tints.
- Implement context-sensitive Card Browser sorting not represented by current
  sort contracts, plus Note Editor navigation, preview, and bulk operations.
- Implement Note Editor navigation, preview, and bulk operations. Wire the
  canonical source search string into structured history row presentation.
- Migrate and track unresolved upstream Card Browser TODO coverage.
- Verify each platform's storage and presentation adapters in its native
  runtime; the shared Flutter implementation has no platform-specific browser
  logic.
