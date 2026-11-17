# Cross-platform Card Browser gap ledger

The Flutter Card Browser is shared across Android, iOS, Web, Windows, macOS,
and Linux. Collection queries and preference behavior live in shared Dart;
platform adapters provide storage and presentation.

## Implemented through Unit 20

- Cards/Notes mode loads and saves through the active collection's
  `browserTableShowNotesMode` config. Cards remains the default.
- Cards and Notes columns and sort settings persist independently using
  AnkiDroid's `activeCols`, `activeNoteCols`, `sortType`, `sortBackwards`,
  `noteSortType`, and `browserNoteSortBackwards` keys.
- Notes search uses the shared SQL compiler's Notes result type, selected-deck
  scoping, backend ordering, and 64-bit-safe Note IDs.
- Notes rows render the sort field, tags, card count, and sole-deck name or
  distinct-deck count. Unsupported columns stay explicitly unavailable.
- Saved searches work in either mode. Selection and navigation preserve the
  current row identity; unsupported Note Editor, preview, and bulk operations
  continue to report their existing unavailable errors.

## Remaining migration work

- Complete Core browser-table field rendering, including note-type labels,
  card timing/context fields, and context-sensitive sorts.
- Implement Note Editor navigation, preview, bulk operations, history, and
  search filters.
- Migrate and track unresolved upstream Card Browser TODO coverage.
- Verify each platform's storage and presentation adapters in its native
  runtime; the shared Flutter implementation has no platform-specific browser
  logic.
