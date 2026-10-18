# AnkiDroid source baseline

- Project: [ankidroid/Anki-Android](https://github.com/ankidroid/Anki-Android)
- Release: `2.25.3`
- Tag: [`v2.25.3`](https://github.com/ankidroid/Anki-Android/tree/v2.25.3)
- Commit: [`d9bf072f814a0c37d30a694192593b31ff2df875`](https://github.com/ankidroid/Anki-Android/commit/d9bf072f814a0c37d30a694192593b31ff2df875)
- Retrieved and compared: `2026-10-18` (latest stable release at that time; prereleases excluded)
- Upstream license evidence: root `COPYING` is GNU GPL version 3; adapted Kotlin
  files declare `GPL-3.0-or-later`.

This repository is a partial Dart port of that exact source snapshot. The
current implementation covers deck-picker filtering and visible-row
construction, the headless review-session action lifecycle, and reviewer count
and answer-button next-time presentation models; it does not claim to reproduce
the whole Android app.

## Source-to-Dart mapping

| AnkiDroid 2.25.3 source | Dart port | Covered behavior |
| --- | --- | --- |
| `AnkiDroid/src/main/java/com/ichi2/anki/deckpicker/DeckFilters.kt` | `lib/src/deck_filters.dart`, `lib/src/locale_lowercase.dart` | Search tokenization with locale-invariant query casing, Kotlin whitespace trimming, path matching, partial-colon matching, and locale/root deck-name casing using the current platform locale on each match |
| Unicode 15.0.0 UCD `UnicodeData.txt`, `PropList.txt`, `DerivedCoreProperties.txt`, and `SpecialCasing.txt` | `lib/src/unicode_15_case_data.dart`, `lib/src/locale_lowercase.dart` | Canonical-combining-class, `Soft_Dotted`, `Cased`, and `Case_Ignorable` data plus full lowercase mappings for final sigma and unconditional expansions; see the separate Unicode license notice |
| `AnkiDroid/src/main/java/com/ichi2/anki/deckpicker/DisplayDeckNode.kt` | `lib/src/display_deck_node.dart` | Display-row projection and filtered/collapsed tree flattening; value equality over constructor fields, excluding its mutable `DeckNode` |
| `libanki/src/main/java/com/ichi2/anki/libanki/sched/DeckNode.kt` and `AnkiDroid/src/main/java/com/ichi2/anki/deckpicker/DeckPickerViewModel.kt` | `lib/src/deck_node.dart` | Dart input projection for display rows plus `totalCardsDue()`, summing immediate-child new/review/learning counts to avoid the capped root aggregate and shared subdeck limits; full backend tree construction is not ported |
| `AnkiDroid/src/main/java/com/ichi2/anki/ui/windows/reviewer/ReviewerViewModel.kt` and `AnkiDroid/src/main/java/com/ichi2/anki/ui/windows/reviewer/ReviewerFragment.kt` | `lib/src/review_session.dart` | Scheduler-selected card, question/answer side, rating dispatch, mutation readiness, serialized actions, timebox event gate/continue, and retention of the previously displayed side during queue reloads and failures |
| `libanki/src/main/java/com/ichi2/anki/libanki/sched/Scheduler.kt` | `ReviewScheduler<TSchedulingSnapshot>` in `lib/src/review_session.dart` | Queue and answer adapter contract, including the optional timebox event; scheduling snapshot and rating are forwarded without Dart interval calculations |
| `libanki/src/main/java/com/ichi2/anki/libanki/Collection.kt` | `ReviewTimeboxReached` in `lib/src/review_session.dart` | Carries the elapsed-time limit and answer count emitted by the collection timebox |
| `AnkiDroid/src/main/java/com/ichi2/anki/ui/windows/reviewer/StudyCounts.kt` and `StudyCountsView.kt` | `ReviewQueueCounts` and `ReviewQueueKind` in `lib/src/review_session.dart`; `StudyCounts` in `lib/src/review_presentation.dart` | Copies scheduler counts and active queue, renders each integer with direct decimal `toString()`, and exposes the equality check used to style only the active count |
| `AnkiDroid/src/main/java/com/ichi2/anki/ui/windows/reviewer/AnswerButtonsNextTime.kt` and `libanki/src/main/java/com/ichi2/anki/libanki/sched/Scheduler.kt` | `ReviewNextStateDescriber<T>` and `AnswerButtonsNextTime` in `lib/src/review_presentation.dart` | Passes the current opaque scheduling snapshot to the backend adapter and assigns its first four strings to Again/Hard/Good/Easy in order; no interval calculation or fallback labels |
| `AnkiDroid/src/test/java/com/ichi2/anki/deckpicker/DeckFiltersTest.kt` and `AnkiDroid/src/test/java/com/ichi2/anki/libanki/DeckNodeTest.kt` | `test/` | Behavioral reference cases for this slice |
| `AnkiDroid/src/test/java/com/ichi2/anki/ui/windows/reviewer/ReviewerViewModelTest.kt` and the reviewer action dispatch in `ReviewerViewModel.kt` | `test/review_session_test.dart` | Review-side transitions, mutation readiness, rating forwarding, timebox pausing/continuation, queue advancement, and serialized action behavior |
| `AnkiDroid/src/test/java/com/ichi2/anki/ui/windows/reviewer/StudyCountsViewTest.kt` and the direct four-label mapping in `AnswerButtonsNextTime.kt` | `test/review_presentation_test.dart` | Decimal count strings, active-queue selection, unchanged backend label order, and failure when a required positional label is absent |

## Review backend boundary

AnkiDroid 2.25.3 pins
`io.github.david-allison:anki-android-backend:0.1.68-anki26.05` in
`gradle/libs.versions.toml`. `libanki` delegates queue selection and answering
to that separate Rust backend (`rslib`). The Dart review session therefore
requires an adapter for the pinned backend contract. The queue-state adapter
supplies counts, active queue, scheduling snapshot, and optional timebox event;
`ReviewNextStateDescriber` forwards that snapshot to the backend's
`describeNextStates()` operation and returns its four ordered strings. The
collection database, timebox calculation, generated backend API, and scheduling
algorithm are not included or reimplemented.

## Remaining coverage gaps

Not yet ported: the Android app and platform lifecycle, card template rendering
and media, collection storage, the Rust backend and scheduling algorithm,
synchronization, review timers, timebox calculation and presentation, Android
study-count/answer-button widgets and layout, next-time visibility preference
wiring, leech handling, reviewer undo/redo and auto-advance, JavaScript
card-state mutation integration, imports/exports, notifications, preferences,
and the remaining AnkiDroid modules.
