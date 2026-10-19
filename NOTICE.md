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
  `lib/src/gesture_command_router.dart`. Serialized key-code and Unicode
  bindings, modifiers, validity, card-side behavior, and source equality/hash
  quirks are represented as typed values; axis IDs, Java float parsing, and
  source-style Float serialization are retained. Android preference lookup,
  `KeyEvent` handling, `possibleKeyBindings`, MotionEvent axis handling, display
  strings, `BindingProcessor`, and command execution are not included. The
  headless key/gesture registration and lookup behavior from
  `AnkiDroid/src/main/java/com/ichi2/anki/reviewer/BindingMap.kt` is adapted in
  `lib/src/reviewer_binding_map.dart`; axis registrations are retained without
  MotionEvent matching.
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
  `lib/src/review_session.dart`. The source timebox counter and its automatic
  restart are adapted in `lib/src/review_timebox.dart`; clock, scheduler limit,
  and answer-count values remain adapter inputs.
- `AnkiDroid/src/main/java/com/ichi2/anki/ui/windows/reviewer/ReviewerFragment.kt`
  declares `GPL-3.0-or-later`. Its `secs / 60f` rounded-minute projection is
  adapted in `lib/src/review_timebox.dart`; localized text and the Android
  dialog are not included.
- `AnkiDroid/src/main/java/com/ichi2/anki/previewer/PreviewerViewModel.kt` and
  `CardViewerViewModel.kt` declare `GPL-3.0-or-later`. Previewer navigation
  formulas and side/card transitions are adapted in
  `lib/src/previewer_navigation.dart`; SavedStateHandle and card lookup remain
  outside.
- `AnkiDroid/src/main/java/com/ichi2/anki/browser/BrowserColumnCollection.kt`
  and `CardBrowserColumn.kt` declare `GPL-3.0-or-later`. Column-key parsing,
  load-time fallback/de-duplication, nullable updates and replacement are
  adapted in `lib/src/browser_column_collection.dart`; successful updates can
  retain duplicates until a later load removes them, as in the source. The host
  supplies mode-specific defaults from `BrowserConfig.kt`; its constants
  incorporating upstream AGPL code are not copied, and SharedPreferences,
  backend column values and browser UI remain outside.
- `AnkiDroid/src/main/java/com/ichi2/anki/model/SortType.kt`,
  `libanki/src/main/java/com/ichi2/anki/libanki/SortOrder.kt`, and typed config
  decoding in `libanki/src/main/java/com/ichi2/anki/libanki/Config.kt` declare
  `GPL-3.0-or-later`. Sort-type resolution and ordered save plans are adapted in
  `lib/src/browser_sort_type.dart`; the model receives the active mode's config
  keys, values, and backend column keys from its host. It preserves the shared
  defaults missing or incorrectly typed config values to the source defaults
  and preserves the shared no-sorting flag behavior, including its effect
  across both modes. It does not
  access Android preferences, collection config, or perform backend sorting.
  `BrowserConfig.kt` constants and lookup code are not copied.
- `AnkiDroid/src/main/java/com/ichi2/anki/browser/SearchHistory.kt`,
  `AnkiDroid/src/main/java/com/ichi2/anki/Flag.kt`, and
  `AnkiDroid/src/main/java/com/ichi2/anki/browser/search/CardState.kt` declare
  `GPL-3.0-or-later`; `libanki/src/main/java/com/ichi2/anki/libanki/PythonTypes.kt`
  (Copyright © 2021 David Allison, GPL-3.0-or-later) defines the signed-long
  `DeckId` and `NoteTypeId`. Search-history equality,
  blank detection, recency/eviction, and compact JSON encoding/decoding are
  adapted in `lib/src/browser_search_history.dart` and
  `lib/src/browser_search_history_json.dart`. The codec preserves source field
  names/order and invalid-whole-list fallback; the host handles SharedPreferences
  and entries may contain user-provided search text and filters.
- `AnkiDroid/src/main/java/com/ichi2/anki/browser/search/CardBrowserSearchViewModel.kt`
  and `SearchString.kt` declare `GPL-3.0-or-later`. The view-model's
  Loading/Loaded recent-history display projection, collapsed five-entry limit,
  expansion state, and toggle threshold are adapted in
  `lib/src/browser_search_history_display.dart`; SavedStateHandle, StateFlow,
  search-string conversion, and Android widgets remain outside.
- `AnkiDroid/src/main/java/com/ichi2/anki/browser/search/SavedSearches.kt`
  declares `GPL-3.0-or-later`. Its named saved-search value behavior,
  case-sensitive ordering and lookup, duplicate rejection, query normalization,
  and map/list conversion are adapted in `lib/src/browser_saved_searches.dart`.
  `SavedSearches.kt` defines the `Config.savedFilters` extension, while
  `Config.kt` supplies the generic typed get/set operations it uses. Collection
  config access and saved-search UI are not included.
- Behavioral cases in `test/deck_filters_test.dart` are adapted from
  `DeckFiltersTest.kt`, Copyright © 2026 Arthur Milchior.
- Behavioral cases in `test/deck_list_test.dart` are adapted from
  `DeckNodeTest.kt`, Copyright © 2025 Shridhar Goel.
- `test/review_session_test.dart` checks the reviewer flow recorded in
  `ReviewerViewModel.kt`, `Scheduler.kt`, and `Collection.kt`; it is not a port
  of the Android test harness.
- `test/review_timebox_test.dart` checks the strict threshold, zero disablement,
  result payload, answer delta, restart reads, negative-limit behavior, and
  rounded-minute conversion from `Collection.kt` and `ReviewerFragment.kt`;
  there is no direct upstream `timeboxReached()` unit test, and this is not a
  port of the Android test harness.
- `test/previewer_navigation_test.dart` adapts the navigation cases in
  `PreviewerViewModelTest.kt`; it does not port the Android test harness,
  collection, or card-rendering setup.
- `test/browser_column_collection_test.dart` adapts the active-column collection
  cases in `BrowserColumnCollectionTest.kt`; it does not port SharedPreferences,
  backend column setup, or the Android test harness.
- `test/browser_sort_type_test.dart` adapts the sort resolution and save cases in
  `SortTypeTest.kt`, plus typed config fallback behavior from `Config.kt`,
  including the source's global no-sorting behavior; it does not port
  preference/config storage or the Android test harness.
- `test/browser_search_history_test.dart` adapts recency, duplicate, truncation,
  removal, clear, canonical serialized JSON, and malformed/invalid-code fallback
  behavior in `SearchHistoryTest.kt`, `FlagSerializerTest.kt`, and
  `CardStateSerializerTest.kt`; it does not test Android preferences or
  collection-backed search query generation.
- `test/browser_search_history_display_test.dart` adapts collapsed/expanded
  recent-history presentation, five-entry truncation/toggle behavior, and
  Loading/Loaded shape handling from `CardBrowserSearchViewModelTest.kt`; it
  does not test Android flows, search-string conversion, or widgets.
- `test/browser_saved_searches_test.dart` adapts name ordering and lookup,
  duplicate handling, query normalization, remove/clear, and map conversion
  behavior from `SavedSearchesTest.kt`; it does not test collection config IO,
  query execution, or the Android test harness.
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
- `test/reviewer_binding_codec_test.dart` and
  `test/reviewer_binding_types_test.dart` check serialized binding framing,
  typed key/Unicode parsing, modifiers, UTF-16 behavior, source equality/hash,
  gesture names and sides, permissive prefix and fallback behavior, invalid
  omission, and router-adapter filtering recorded in `BindingTest.kt`,
  `MappableBindingTest.kt`, and applicable `BindingAndroidTest.kt` cases; they
  are not ports of the Android test harness.
- `test/reviewer_binding_map_test.dart` checks ordered duplicate registration,
  side-independent lookup with the original side retained, separate axis
  registrations, and skipping unknown bindings, based on `BindingMap.kt` and
  `BindingMapTest.kt`; Android event handling and processor execution are not
  included.
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
`BindingTest.kt`, `MappableBindingTest.kt`, `BindingMap.kt`,
`BindingMapTest.kt`, and applicable `BindingAndroidTest.kt` cases.
They are not a port of the Android test harness.
