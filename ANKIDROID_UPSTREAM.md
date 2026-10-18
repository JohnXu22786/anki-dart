# AnkiDroid source baseline

- Project: [ankidroid/Anki-Android](https://github.com/ankidroid/Anki-Android)
- Release: `2.25.3`
- Tag: [`v2.25.3`](https://github.com/ankidroid/Anki-Android/tree/v2.25.3)
- Commit: [`d9bf072f814a0c37d30a694192593b31ff2df875`](https://github.com/ankidroid/Anki-Android/commit/d9bf072f814a0c37d30a694192593b31ff2df875)
- Retrieved and compared: `2026-10-18` (latest published release at that time)
- Upstream license evidence: root `COPYING` is GNU GPL version 3; adapted Kotlin
  files declare `GPL-3.0-or-later`.

This repository is a partial Dart port of that exact source snapshot. The
current implementation covers the deck picker's filtering and visible-row
construction only; it does not claim to reproduce the whole Android app.

## Source-to-Dart mapping

| AnkiDroid 2.25.3 source | Dart port | Covered behavior |
| --- | --- | --- |
| `AnkiDroid/src/main/java/com/ichi2/anki/deckpicker/DeckFilters.kt` | `lib/src/deck_filters.dart` | Search tokenization, path matching, partial-colon matching, case handling |
| `AnkiDroid/src/main/java/com/ichi2/anki/deckpicker/DisplayDeckNode.kt` | `lib/src/display_deck_node.dart` | Display-row projection and filtered/collapsed tree flattening |
| `libanki/src/main/java/com/ichi2/anki/libanki/sched/DeckNode.kt` | `lib/src/deck_node.dart` | Dart input projection for the fields consumed by display rows; full backend tree construction is not ported |
| `AnkiDroid/src/test/java/com/ichi2/anki/deckpicker/DeckFiltersTest.kt` and `AnkiDroid/src/test/java/com/ichi2/anki/libanki/DeckNodeTest.kt` | `test/` | Behavioral reference cases for this slice |

Not yet ported: the Android app and UI, collection/backend implementation,
scheduling, synchronization, media, imports/exports, widgets, notifications,
preferences, and the remaining AnkiDroid modules.
