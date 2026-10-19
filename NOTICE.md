# Notices

This repository contains a partial, modified Dart port of code from
[AnkiDroid](https://github.com/ankidroid/Anki-Android), release 2.25.3, commit
`d9bf072f814a0c37d30a694192593b31ff2df875`. It is an independent project and
does not imply endorsement by the AnkiDroid or Anki projects.

## Adapted source

- `AnkiDroid/src/main/java/com/ichi2/anki/deckpicker/DeckFilters.kt` is
  Copyright © 2026 Arthur Milchior <arthur@milchior.fr>. Its Dart adaptation is
  `lib/src/deck_filters.dart`.
- `AnkiDroid/src/main/java/com/ichi2/anki/deckpicker/DisplayDeckNode.kt` is
  Copyright © 2025 Gautam Bhetanabhotla <gautamarcturus@gmail.com>. Its Dart
  adaptation is `lib/src/display_deck_node.dart`.
- `libanki/src/main/java/com/ichi2/anki/libanki/sched/DeckNode.kt` is Copyright
  © 2020 Arthur Milchior <arthur@milchior.fr>. Its Dart input projection and
  `totalCardsDue()` behavior are in `lib/src/deck_node.dart`; the total sums
  immediate child aggregates as used by `DeckPickerViewModel.kt`.
- `AnkiDroid/src/main/java/com/ichi2/anki/ui/windows/reviewer/ReviewerViewModel.kt`
  is marked `GPL-3.0-or-later` in its upstream header. Its reviewer action and
  queue lifecycle, including the current-card mutation readiness barrier, is
  adapted by `lib/src/review_session.dart`; the upstream file does not state an
  individual copyright holder.
- `libanki/src/main/java/com/ichi2/anki/libanki/sched/Scheduler.kt` is Copyright
  © 2022 Ankitects Pty Ltd. The Dart adapter contract in
  `lib/src/review_session.dart` reflects its queue and answer entry points, and
  `lib/src/review_presentation.dart` reflects its `describeNextStates()` entry
  point; the Rust scheduler implementation is not included.
- `libanki/src/main/java/com/ichi2/anki/libanki/sched/Counts.kt` is Copyright
  © 2020 Arthur Milchior <arthur@milchior.fr>. Its three scheduler counts and
  queue enum are projected into `ReviewQueueCounts` and `ReviewQueueKind` in
  `lib/src/review_session.dart`.
- `AnkiDroid/src/main/java/com/ichi2/anki/ui/windows/reviewer/StudyCounts.kt`,
  `StudyCountsView.kt`, and `AnswerButtonsNextTime.kt` are marked
  `GPL-3.0-or-later` in the upstream source. Their count strings, active-queue
  condition, and four backend label assignments are adapted by
  `lib/src/review_presentation.dart`; the Android view widgets are not included.
- `AnkiDroid/src/main/java/com/ichi2/anki/ui/windows/reviewer/AnswerTimer.kt`
  and `AnswerTimerState.kt` are marked `GPL-3.0-or-later` upstream. Their
  hidden/running/paused/stopped state machine is adapted in
  `lib/src/answer_timer.dart`; host lifecycle registration and timer rendering
  are not included.
- `AnkiDroid/src/main/java/com/ichi2/anki/ui/windows/reviewer/autoadvance/AutoAdvance.kt`,
  `AutoAdvanceSettings.kt`, `AutoAdvanceAction.kt`, `QuestionAction.kt`, and
  `AnswerAction.kt` are marked `GPL-3.0-or-later` upstream. Their settings
  contract, action codes, delay dispatch, and cooperative in-flight cancellation
  signal are adapted
  in `lib/src/auto_advance.dart`; the Android collection settings lookup and
  reviewer action routing are not included.
- `AnkiDroid/src/main/java/com/ichi2/anki/ui/windows/reviewer/GestureParser.kt`
  and `AnkiDroid/src/main/java/com/ichi2/anki/cardviewer/Gesture.kt` declare
  `GPL-3.0-or-later`. Their gesture enums, decoded-input decisions, viewport
  mapping, tap timing, and cancellation of pending delayed taps are adapted in
  `lib/src/gesture_parser.dart`; Android Uri/WebView/preferences integration is
  not included.
- `AnkiDroid/src/main/java/com/ichi2/anki/cardviewer/GestureProcessor.kt`,
  `Gesture.kt`, and `ViewerCommand.kt`, together with
  `AnkiDroid/src/main/java/com/ichi2/anki/reviewer/ReviewerBinding.kt` and
  `Binding.kt`, declare `GPL-3.0-or-later`. Their gesture-to-command mapping,
  command identifiers/order, corner gating, and execution-result behavior are
  adapted in `lib/src/gesture_command_router.dart`; Android preference lookup,
  input events, and command handlers are not included.
- `AnkiDroid/src/main/java/com/ichi2/anki/reviewer/MappableBinding.kt`,
  `ReviewerBinding.kt`, `Binding.kt`, `Axis.kt`, and `CardSide.kt` declare
  `GPL-3.0-or-later`. Their serialized reviewer-binding codec and gesture
  preference adapter are adapted in `lib/src/reviewer_binding_codec.dart` and
  `lib/src/gesture_command_router.dart`. Keyboard and Unicode bindings are only
  recognized for non-gesture round trips; axis IDs, Java float parsing and
  source-style Float serialization are retained, while runtime axis handling
  is not included. Android preference lookup, key
  events, display strings, and `BindingMap` are not included.
- `compat/src/main/java/com/ichi2/anki/compat/BaseCompat.kt` is Copyright
  © 2017 Profpatsch <mail@profpatsch.de>. Its fallback gesture-axis IDs are
  referenced by the codec's syntax check; the compatibility layer itself is
  not ported.
- `libanki/src/main/java/com/ichi2/anki/libanki/DeckConfig.kt` is Copyright
  © 2020 David Allison <davidallisongithub@gmail.com> and Arthur Milchior
  <Arthur@Milchior.fr>. Its Auto Advance fields and defaults remain behind the
  `AutoAdvanceSettingsAdapter`; the Dart port does not copy its storage access
  or property wrappers.
- `libanki/src/main/java/com/ichi2/anki/libanki/Collection.kt` contains
  `Collection.TimeboxReached`, Copyright © 2026 Mike Hardy
  <github@mikehardy.net>. Its `secs` and `reps` payload is adapted by
  `ReviewTimeboxReached` in
  `lib/src/review_session.dart`; collection timebox calculation is not included.
- Behavioral cases in `test/deck_filters_test.dart` are adapted from
  `DeckFiltersTest.kt`, Copyright © 2026 Arthur Milchior.
- Behavioral cases in `test/deck_list_test.dart` are adapted from
  `DeckNodeTest.kt`, Copyright © 2025 Shridhar Goel.
- `test/review_session_test.dart` checks the reviewer flow recorded in
  `ReviewerViewModel.kt`, `Scheduler.kt`, and `Collection.kt`; it is not a port
  of the Android test harness.
- `test/review_presentation_test.dart` checks the count and answer-label
  projection recorded in `StudyCounts.kt`, `StudyCountsViewTest.kt`,
  `AnswerButtonsNextTime.kt`, and `Scheduler.kt`; it is not a port of the
  Android test harness.
- `test/answer_timer_test.dart` checks the timer behavior and boundary cases
  from `AnswerTimerTest.kt`; it is not a port of the Android test harness.
- `test/auto_advance_test.dart` checks the delay, cancellation, deck-setting,
  action-code, and same-side behavior recorded in `AutoAdvanceTest.kt`; it is
  not a port of the Android test harness.
- `test/gesture_parser_test.dart` checks the input, target, swipe, scroll,
  malformed-data, and asynchronous timing behavior recorded in
  `GestureParserTest.kt`; it is not a port of the Android test harness.
- `test/gesture_command_router_test.dart` checks command ordering, the source
  center-tap dispatch, corner and multitap filtering, enabled-state behavior,
  and executor results recorded in `GestureProcessorTest.kt`; it is not a port
  of the Android test harness.
- `test/reviewer_binding_codec_test.dart` checks serialized binding framing,
  gesture names and sides, permissive prefix and fallback behavior, invalid
  omission, UTF-16 suffix behavior, and router-adapter filtering recorded in
  `BindingTest.kt`, `MappableBindingTest.kt`, and applicable
  `BindingAndroidTest.kt` cases; it is not a port of the Android test harness.
- Dart adaptations, the review-session controller, timer, Auto Advance and
  gesture models, and new test code are Copyright © 2026 John Tsui.

## Unicode property data

The locale-casing property ranges and full lowercase mappings in
`lib/src/unicode_15_case_data.dart` are derived from Unicode 15.0.0
`UnicodeData.txt`, `PropList.txt`, `DerivedCoreProperties.txt`, and
`SpecialCasing.txt`; the BMP decimal-digit block starts in the same file are
derived from Unicode 15.0.0 `UnicodeData.txt`. Copyright © 2022 Unicode, Inc.
This data is distributed under Unicode License V3. Its local SPDX identifier is
`LicenseRef-Unicode-License-V3`; the license text is included at
`LICENSES/Unicode-License-V3.txt`.

The adapted AnkiDroid source is licensed under GNU GPL version 3 or any later
version (`GPL-3.0-or-later`). The pinned scheduler binary is an external
dependency and is not redistributed here. See the notices in each source file
and the full license text in `COPYING` and `LICENSES/GPL-3.0-or-later.txt`.

The tests were written against the behavior documented and exercised by
AnkiDroid's `DeckFiltersTest.kt`, `DeckNodeTest.kt`, reviewer flow,
`AnswerTimerTest.kt`, `GestureParserTest.kt`, `GestureProcessorTest.kt`,
`BindingTest.kt`, `MappableBindingTest.kt`, and applicable
`BindingAndroidTest.kt` cases.
They are not a port of the Android test harness.
