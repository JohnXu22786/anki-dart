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
construction, the headless review-session action lifecycle, reviewer count and
answer-button next-time presentation models, the reviewer answer-timer state
machine, the reviewer Auto Advance model, the headless reviewer gesture
parser, parsed-gesture command routing, and a headless codec for serialized
reviewer bindings; it does not claim to reproduce the whole Android app.

## Source-to-Dart mapping

| AnkiDroid 2.25.3 source | Dart port | Covered behavior |
| --- | --- | --- |
| `AnkiDroid/src/main/java/com/ichi2/anki/deckpicker/DeckFilters.kt` | `lib/src/deck_filters.dart`, `lib/src/locale_lowercase.dart` | Search tokenization with locale-invariant query casing, Kotlin whitespace trimming, path matching, partial-colon matching, and locale/root deck-name casing using the current platform locale on each match |
| Unicode 15.0.0 UCD `UnicodeData.txt`, `PropList.txt`, `DerivedCoreProperties.txt`, and `SpecialCasing.txt` | `lib/src/unicode_15_case_data.dart`, `lib/src/locale_lowercase.dart` | Canonical-combining-class, `Soft_Dotted`, `Cased`, and `Case_Ignorable` data; BMP decimal-digit block starts for Kotlin-compatible gesture query parsing; and full lowercase mappings for final sigma and unconditional expansions; see the separate Unicode license notice |
| `AnkiDroid/src/main/java/com/ichi2/anki/deckpicker/DisplayDeckNode.kt` | `lib/src/display_deck_node.dart` | Display-row projection and filtered/collapsed tree flattening; value equality over constructor fields, excluding its mutable `DeckNode` |
| `libanki/src/main/java/com/ichi2/anki/libanki/sched/DeckNode.kt` and `AnkiDroid/src/main/java/com/ichi2/anki/deckpicker/DeckPickerViewModel.kt` | `lib/src/deck_node.dart` | Dart input projection for display rows plus `totalCardsDue()`, summing immediate-child new/review/learning counts to avoid the capped root aggregate and shared subdeck limits; full backend tree construction is not ported |
| `AnkiDroid/src/main/java/com/ichi2/anki/ui/windows/reviewer/ReviewerViewModel.kt` and `AnkiDroid/src/main/java/com/ichi2/anki/ui/windows/reviewer/ReviewerFragment.kt` | `lib/src/review_session.dart` | Scheduler-selected card, question/answer side, rating dispatch, mutation readiness, serialized actions, timebox event gate/continue, and retention of the previously displayed side during queue reloads and failures |
| `libanki/src/main/java/com/ichi2/anki/libanki/sched/Scheduler.kt` | `ReviewScheduler<TSchedulingSnapshot>` in `lib/src/review_session.dart` | Queue and answer adapter contract, including the optional timebox event; scheduling snapshot and rating are forwarded without Dart interval calculations |
| `libanki/src/main/java/com/ichi2/anki/libanki/Collection.kt` | `ReviewTimeboxReached` in `lib/src/review_session.dart` | Carries the elapsed-time limit and answer count emitted by the collection timebox |
| `AnkiDroid/src/main/java/com/ichi2/anki/ui/windows/reviewer/StudyCounts.kt` and `StudyCountsView.kt` | `ReviewQueueCounts` and `ReviewQueueKind` in `lib/src/review_session.dart`; `StudyCounts` in `lib/src/review_presentation.dart` | Copies scheduler counts and active queue, renders each integer with direct decimal `toString()`, and exposes the equality check used to style only the active count |
| `AnkiDroid/src/main/java/com/ichi2/anki/ui/windows/reviewer/AnswerButtonsNextTime.kt` and `libanki/src/main/java/com/ichi2/anki/libanki/sched/Scheduler.kt` | `ReviewNextStateDescriber<T>` and `AnswerButtonsNextTime` in `lib/src/review_presentation.dart` | Passes the current opaque scheduling snapshot to the backend adapter and assigns its first four strings to Again/Hard/Good/Easy in order; no interval calculation or fallback labels |
| `AnkiDroid/src/main/java/com/ichi2/anki/ui/windows/reviewer/AnswerTimer.kt` and `AnswerTimerState.kt` | `lib/src/answer_timer.dart` | Hidden/running/paused/stopped states; card configuration; stop, lifecycle pause/resume, hide, elapsed-time upper clamp, and resume-at-limit transition, using an injected monotonic millisecond clock in place of `SystemClock.elapsedRealtime()`; exposes current state and a replaying, per-listener conflated stream of distinct states to match `StateFlow` |
| `AnkiDroid/src/main/java/com/ichi2/anki/ui/windows/reviewer/autoadvance/AutoAdvance.kt`, `AutoAdvanceSettings.kt`, `AutoAdvanceAction.kt`, `QuestionAction.kt`, `AnswerAction.kt`, plus setting fields in `libanki/src/main/java/com/ichi2/anki/libanki/DeckConfig.kt` | `lib/src/auto_advance.dart` | Loads explicit deck settings through `AutoAdvanceSettingsAdapter`; exposes wait-for-audio; schedules typed question/answer actions; preserves enable/disable, card-change and opposite-side cancellation, exact action codes/fallbacks, and the same-side job-overwrite behavior. Each listener receives an explicit cancellation signal and can cooperatively stop suspended work when its source job is cancelled. DeckConfig storage and defaults stay in the adapter. |
| `AnkiDroid/src/main/java/com/ichi2/anki/ui/windows/reviewer/GestureParser.kt`, nested `GestureData`/`WebViewState`, and `AnkiDroid/src/main/java/com/ichi2/anki/cardviewer/Gesture.kt` (`Gesture`, `TapGestureMode`) | `lib/src/gesture_parser.dart`, `lib/src/unicode_15_case_data.dart` | Decoded input, explicit timeout/mode/sensitivity config and viewport adapter; multi-finger mapping; Kotlin-compatible signed integer parsing, including BMP Unicode decimal digits and UTF-16 surrogate behavior; four/nine-point taps; Float32 scale/scroll and threshold math; dominant-axis swipes with scroll suppression; malformed-query callback behavior; deferred single and immediate double taps, preserving timeout boundaries, zero-sentinel timing, signed 64-bit subtraction, and same-side job overwrite. A canceled delay suppresses its pending callback. Android Uri/WebView/preferences integration remains outside. |
| `AnkiDroid/src/main/java/com/ichi2/anki/cardviewer/GestureProcessor.kt`, `Gesture.kt`, `ViewerCommand.kt`, and `AnkiDroid/src/main/java/com/ichi2/anki/reviewer/ReviewerBinding.kt` / `Binding.kt` | `lib/src/gesture_command_router.dart` and `Gesture` in `lib/src/gesture_parser.dart` | Retains command enum identifiers and declaration order; resolves host-supplied gesture bindings in that order so later commands overwrite duplicates; gates the four corner taps and center tap on explicit corner-touch configuration; leaves two/three/four-finger taps unmapped; makes `isEnabled` gate only `isBound`; returns `false` for null/unmapped gestures, `null` for mapped gestures without an executor, and otherwise forwards the command and original gesture to the optional callback. Android preference decoding, touch input, and command handlers remain outside. |
| `AnkiDroid/src/main/java/com/ichi2/anki/reviewer/MappableBinding.kt`, `ReviewerBinding.kt`, `Binding.kt`, `Axis.kt`, `CardSide.kt`, and axis fallback IDs in `compat/src/main/java/com/ichi2/anki/compat/BaseCompat.kt` | `lib/src/reviewer_binding_codec.dart` | Versioned `1/` list framing, `|` splitting with empty-item filtering, reviewer prefix and side suffix encoding, exact gesture enum names, permissive optional `r` removal, UTF-16 code-unit suffix handling, unknown suffix fallback to BOTH, and invalid-binding omission on write. Typed key-code and Unicode bindings preserve modifier parsing/output order, Kotlin Int32 limits, UTF-16 first-code-unit selection, validity and `isKey`; Unicode deserialization accepts `|` while the source factory rejects it. Reviewer-side BOTH wildcard equality, side-independent wrapper hash, key/Unicode modifier-sensitive equality with modifier-insensitive binding hashes, semi-structural modifier comparison, and unknown data-object equality are represented. Axis IDs are checked against `Axis`; Kotlin integer parsing accepts BMP Unicode decimal digits, Java float syntax (including hexadecimal floats) is parsed to binary32 and normalized in the source `Float.toString` style, and extra space-separated axis tokens are ignored like the source. Android KeyEvent/possibleKeyBindings, MotionEvent axis handling, display strings, and BindingMap remain outside. |
| `AnkiDroid/src/main/java/com/ichi2/anki/cardviewer/GestureProcessor.kt`, `ViewerCommand.kt`, and `ReviewerBinding.kt` | `GestureCommandRouter.fromPreferenceValues()` in `lib/src/gesture_command_router.dart` | Takes host-supplied serialized preference values, leaves missing values empty rather than applying keyboard defaults, and feeds only decoded gesture values into the existing source-ordered router. Side values are not used as routing filters. Android `SharedPreferences` lookup remains outside. |
| `AnkiDroid/src/test/java/com/ichi2/anki/deckpicker/DeckFiltersTest.kt` and `AnkiDroid/src/test/java/com/ichi2/anki/libanki/DeckNodeTest.kt` | `test/` | Behavioral reference cases for this slice |
| `AnkiDroid/src/test/java/com/ichi2/anki/ui/windows/reviewer/ReviewerViewModelTest.kt` and the reviewer action dispatch in `ReviewerViewModel.kt` | `test/review_session_test.dart` | Review-side transitions, mutation readiness, rating forwarding, timebox pausing/continuation, queue advancement, and serialized action behavior |
| `AnkiDroid/src/test/java/com/ichi2/anki/ui/windows/reviewer/StudyCountsViewTest.kt` and the direct four-label mapping in `AnswerButtonsNextTime.kt` | `test/review_presentation_test.dart` | Decimal count strings, active-queue selection, unchanged backend label order, and failure when a required positional label is absent |
| `AnkiDroid/src/test/java/com/ichi2/anki/ui/windows/reviewer/AnswerTimerTest.kt` | `test/answer_timer_test.dart` | Clock-controlled source cases for initial/configured state, elapsed values, pause/resume, clamping, hide/stop transitions, and the source's negative-delta and nonpositive-limit behavior |
| `AnkiDroid/src/test/java/com/ichi2/anki/ui/windows/reviewer/autoadvance/AutoAdvanceTest.kt` | `test/auto_advance_test.dart` | Deterministic cases for positive delays, typed action dispatch, disabled/nonpositive timers, cancellation on disable/side/card change, deck settings reload and wait-for-audio, action codes/fallbacks, and same-side job overwrite |
| `AnkiDroid/src/test/java/com/ichi2/anki/ui/windows/reviewer/GestureParserTest.kt` | `test/gesture_parser_test.dart` | Source-derived cases for malformed input, multi-finger taps, grid/diagonal boundaries, viewport adjustment, strict scaled swipe thresholds, dominant-axis selection, scroll suppression, and asynchronous tap timing/cancellation |
| `AnkiDroid/src/test/java/com/ichi2/anki/cardviewer/GestureProcessorTest.kt` | `test/gesture_command_router_test.dart` | The source center-tap integration behavior plus command-order overwrite, corner configuration, deliberately unmapped multitaps, enabled-state semantics, nullable execution results, and callback forwarding |
| `AnkiDroid/src/test/java/com/ichi2/anki/reviewer/BindingTest.kt`, `MappableBindingTest.kt`, and applicable preference parsing cases from `BindingAndroidTest.kt` | `test/reviewer_binding_codec_test.dart`, `test/reviewer_binding_types_test.dart` | Source-derived preference framing, gesture/side behavior, typed key and Unicode parsing/serialization, modifier parsing, Int32 and UTF-16 boundaries, factory/deserialization distinction, source equality/hash quirks, malformed/unknown omission, Java float syntax and normalization, extra axis-token handling, and router filtering; Android KeyEvent behavior is excluded |

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

`AutoAdvanceSettingsAdapter` loads the five resolved settings for the current
card's deck. This boundary keeps `Card.currentDeckId()` and `DeckConfig` access
outside the headless timer model and leaves the source's deck-option defaults to
the adapter. `AutoAdvanceScheduler` supplies cancellable delays and can be
replaced with a deterministic scheduler in tests. The listener receives an
explicit `AutoAdvanceCancellation` signal; adapters must observe it while
awaiting cancellation-sensitive work, matching the source coroutine's
cooperative cancellation. Synchronous side effects already performed are not
rolled back.

## Remaining coverage gaps

Not yet ported: the Android app and platform lifecycle integration, card
template rendering and media, collection storage, the Rust backend and
scheduling algorithm, synchronization, answer-timer widget/tick rendering,
timebox calculation and presentation, Android study-count/answer-button
widgets and layout, next-time visibility preference wiring, Auto Advance deck
settings UI and actual collection-backed settings loader, reviewer action
routing and audio lifecycle integration, leech handling, reviewer undo/redo,
JavaScript card-state mutation and gesture bridges, WebView state collection,
Android preference and timeout lookup, imports/exports, notifications,
preferences, and the remaining AnkiDroid modules. Gesture parsing, serialized
reviewer binding codec, and parsed-gesture command routing are platform-
independent models; Android `KeyEvent` handling and `possibleKeyBindings`, display
strings, MotionEvent axis interpretation, `BindingMap`, touch input, and reviewer
command execution are not ported. The Android WebView integration is not ported.
The Dart answer-timer model exposes pause/resume calls and an observable state
stream but does not register a platform lifecycle observer or render timer ticks.
