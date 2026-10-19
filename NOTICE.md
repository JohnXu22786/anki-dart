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
  The `ViewerCommand.defaultValue` lists are adapted in
  `lib/src/reviewer_command_defaults.dart`, preserving symbolic key names,
  Unicode values, sides, modifiers, order, and empty entries. The host supplies
  numeric Android key-code mappings. `ReviewerBindingPreferenceResolver` in
  `lib/src/reviewer_binding_preference_resolver.dart` uses defaults only when
  the host supplies a null preference; every configured string replaces them
  through the codec, including empty and malformed values. Preference lookup
  remains with the host.
- `AnkiDroid/src/main/java/com/ichi2/anki/reviewer/AnswerButtons.kt` and
  `AutomaticAnswer.kt` declare `GPL-3.0-or-later`. Their answer-rating to
  `ViewerCommand` mapping, automatic-action config values, unknown-value
  fallback, and optional command result are adapted in
  `lib/src/reviewer_answer_action.dart`. The upstream REUSE annotation attributes
  Kotlin source copyright to Contributors to the AnkiDroid project. Deck-config
  access, command execution, logging, and localized reminder UI remain with the
  host.
- `AnkiDroid/src/main/java/com/ichi2/anki/reviewer/MappableBinding.kt`,
  `ReviewerBinding.kt`, `Binding.kt`, `Axis.kt`, and `CardSide.kt` declare
  `GPL-3.0-or-later`. Their serialized reviewer-binding codec and gesture
  preference adapter are adapted in `lib/src/reviewer_binding_codec.dart` and
  `lib/src/gesture_command_router.dart`. Serialized key-code and Unicode
  bindings, modifiers, validity, card-side behavior, and source equality/hash
  quirks are represented as typed values; axis IDs, Java float parsing, and
  source-style Float serialization are retained. Android preference lookup,
  `KeyEvent` extraction, platform `getUnicodeChar()` calculation,
  MotionEvent extraction and device handling, display strings, Android `BindingProcessor`
  wiring, and command execution are not included. The
  headless key/gesture registration and lookup behavior from
  `AnkiDroid/src/main/java/com/ichi2/anki/reviewer/BindingMap.kt` is adapted in
  `lib/src/reviewer_binding_map.dart`; axis registrations are retained there.
  Their threshold and debounce behavior over host-provided Float32 values is
  adapted in `lib/src/reviewer_axis_dispatch.dart`. Projected key candidate
  construction and sequential dispatch are adapted in
  `lib/src/reviewer_key_dispatch.dart`; the host must supply the Unicode result
  computed with the Shift/NumLock meta-state mask.
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
  The history and saved-search availability projections from
  `searchHistoryAvailableFlow` and `canManageSavedSearchesFlow` are adapted in
  `lib/src/browser_availability.dart`; the host supplies the current values and
  owns flow updates and widgets.
- `AnkiDroid/src/main/java/com/ichi2/anki/browser/search/CardBrowserSearchViewModel.kt`,
  `SearchFilters.kt`, and `SearchRequest.kt` declare `GPL-3.0-or-later`. Their
  structured history/request transformations are adapted in
  `lib/src/browser_search_request.dart`. The host supplies deck and note-type
  name/ID values; only those mapping fields are represented from `Decks.kt` and
  `Notetypes.kt`. `Decks.kt` is Copyright © 2025 David Allison; `Notetypes.kt`
  credits Daniel Svärd, Rick Gruber-Riemer, Norbert Nagold, Kostas Spyropoulos,
  and David Allison. Both files also identify separately incorporated AGPL
  material; none of that backend implementation is copied here. Collection
  access, backend query generation, and execution are not included. The view
  model's `FilterUpdate` origin and one-snapshot request projection are adapted
  in `lib/src/browser_filter_update.dart`; StateFlow/coroutine timing and
  field-specific setter updates remain with the host. The Basic/Advanced text
  buffers and transition methods are adapted in
  `lib/src/browser_search_text_state.dart`; SavedStateHandle persistence,
  flow scheduling, and Android text widgets remain with the host.
  The ordered effects for `selectSearchHistoryEntry` and its LF-only text edit
  are projected in `lib/src/browser_search_state_effects.dart`, reusing the
  host-mapped history restoration; the host applies flows and performs search
  submission. The pinned test named “selecting search history entry” calls the
  `submitSearch` helper rather than this method, so the selection sequence is
  covered by source-derived Dart cases rather than a direct upstream test. No
  pinned test directly covers host-map restoration through `SearchFilters.from`.
  The source `syncState` and `resetSearchState` method call order is projected
  as typed effects in `lib/src/browser_search_state_effects.dart`. The reset
  preserves the exact query and omits `historyExpanded` from the three ordered
  key removals. The host performs the StateFlow and SavedStateHandle operations;
  the source marks reset `@NeedsTest("reset")` and has no direct reset or sync
  test. The `submitCurrentSearch(SearchRequest)` overload is also projected in
  `lib/src/browser_search_state_effects.dart`: it records the trimmed ID-based
  history entry using the existing recency rules, publishes the updated history
  as Loading, then emits the close-view event and exact submitted request. It
  does not set screen-open state or execute the search. The pinned view-model
  test helper calls the no-argument submit overload instead, so its ordered
  effects are covered by source-derived Dart tests, not a direct upstream test.
- `AnkiDroid/src/main/java/com/ichi2/anki/browser/search/SearchRequest.kt`,
  `AnkiDroid/src/main/java/com/ichi2/anki/browser/search/SearchFilters.kt`,
  `AnkiDroid/src/main/java/com/ichi2/anki/Flag.kt`, and
  `AnkiDroid/src/main/java/com/ichi2/anki/browser/search/CardState.kt` declare
  `GPL-3.0-or-later`. Their pre-backend
  query and filter-node construction behavior is represented in
  `lib/src/browser_search_node_plan.dart`; Kotlin-compatible whitespace
  trimming is shared through `lib/src/kotlin_whitespace.dart`. The plan keeps
  stored flag/card-state codes separate from semantic search values and models
  query inclusion and boolean grouping. `Collection.kt` is GPL-3.0-or-later,
  Copyright © 2011 Norbert Nagold, 2012 Kostas Spyropoulos, and 2022 Ankitects;
  only its `groupSearches()` singleton-collapse behavior is referenced. That
  file also incorporates separate AGPL-3.0-or-later code, which is not copied
  into this port. The backend protobuf SearchNode, parser/validation,
  SearchString serialization, and execution are not included.
- `AnkiDroid/src/main/java/com/ichi2/anki/browser/search/SavedSearches.kt`
  declares `GPL-3.0-or-later`. Its named saved-search value behavior,
  case-sensitive ordering and lookup, duplicate rejection, query normalization,
  and map/list conversion are adapted in `lib/src/browser_saved_searches.dart`.
  `SavedSearches.kt` defines the `Config.savedFilters` extension, while
  `Config.kt` supplies the generic typed get/set operations it uses. Collection
  config access and saved-search UI are not included. The outcome mapping from
  `CardBrowserSearchViewModel.kt`'s `addSavedSearch`/`deleteSavedSearch` methods
  and `UserMessage` enum is adapted in `lib/src/browser_saved_search_messages.dart`;
  only message identifiers are returned, while localization, UI and message-flow
  delivery remain with the host.
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
  cases in `BrowserColumnCollectionTest.kt`, including constructor aliasing
  and cached count, and adds a source-derived snapshot key-projection check; it
  does not port SharedPreferences, backend column setup, or the Android harness.
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
  Loading's construction-time entry/null-pair projection and Loaded shape from
  `CardBrowserSearchViewModelTest.kt`, with an added source-derived Loading
  snapshot check; it does not test Android flows, search-string conversion, or
  widgets.
- `test/browser_search_restore_test.dart` uses source-derived request/history
  conversion cases, with `SearchHistoryTest.kt` as the history-format reference
  and `CardBrowserSearchViewModel.kt` as the host-map restoration implementation.
  It covers first-match ID mapping, duplicate/order preservation, Kotlin query
  trimming, and missing-ID failure. The pinned history tests cover invalid IDs
  during search-string generation, not direct restoration through host maps.
  Collection lookup and backend query generation remain outside this model.
- `test/browser_search_text_state_test.dart` adapts Basic/Advanced mode and text
  transitions from `CardBrowserSearchViewModelTest.kt`, including append spacing,
  LF replacement, saved-query application, and independent buffers; it does not
  test SavedStateHandle, flow scheduling, or Android text widgets.
- `test/browser_search_state_effects_test.dart` adds source-derived cases for
  `syncState`/`resetSearchState` effect order, verbatim request/filter values,
  and the exact three SavedState keys removed. The pinned source marks reset
  `@NeedsTest("reset")` but has no direct test for either method; host execution
  and coroutine scheduling remain outside this test.
- `test/browser_search_submit_effects_test.dart` adds source-derived cases for
  the `SearchRequest` submit overload: trimmed ID-based history conversion,
  history Loading before close-view and request events, blank-query history
  suppression/inclusion, and exact submitted-request identity. The similarly
  named pinned view-model test helper exercises the no-argument overload, not
  this ordered event sequence. Persistence, event delivery, and search execution
  remain host responsibilities.
- `test/browser_search_history_selection_test.dart` adds source-derived cases
  for history-selection effect order, active Basic/Advanced text replacement,
  LF/CR behavior, restored filters, and empty-filter fallback on missing IDs.
  The similarly named pinned test calls `submitSearch`, not
  `selectSearchHistoryEntry`; this model does not execute Android flows or
  search submission.
- `test/browser_saved_searches_test.dart` adapts name ordering and lookup,
  duplicate handling, query normalization, remove/clear, and map conversion
  behavior from `SavedSearchesTest.kt`; it does not test collection config IO,
  query execution, or the Android test harness.
- `test/browser_saved_search_messages_test.dart` adapts the four direct
  `CardBrowserSearchViewModelTest.kt` cases for successful/duplicate add and
  successful/missing delete. It checks source message identifiers only; it does
  not test localization, Android message-flow delivery, or UI rendering.
- `test/browser_availability_test.dart` adapts the direct empty-history and
  saved-search false/true/false availability cases from
  `CardBrowserSearchViewModelTest.kt`, with added Loading/Loaded list-shape
  checks. Android flow scheduling and widgets remain outside.
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
- `test/reviewer_command_defaults_test.dart` checks that every command has a
  table entry and the exact empty-default set, plus representative answer,
  Unicode and modifier bindings, key-name resolution, duplicate numeric
  values, and the aggregate membership cases from `MappableBindingTest.kt`; it
  is not a port of the Android test harness.
- `test/reviewer_binding_preference_resolver_test.dart` checks null-only
  default selection, source-order defaults, configured override behavior,
  empty/unsupported/malformed values, and the configured path's independence
  from host key-name resolution.
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
  `BindingMapTest.kt`; Android event decoding and command execution are not
  included.
- `test/reviewer_key_dispatch_test.dart` checks projected key candidate order,
  modifier matching, repeat suppression, Unicode code-unit truncation and
  separator omission, and callback order/short-circuit behavior from
  `Binding.kt` and `BindingMap.kt`; it does not test Android `KeyEvent` access
  or keyboard-layout Unicode generation.
- `test/reviewer_axis_dispatch_test.dart` checks inclusive threshold comparisons,
  per-registration debounce/rearm, Float32 value handling, ordered multiple
  triggers, processor-result independence, and null-event/no-registration cases
  derived from `SingleAxisDetector.kt` and `BindingMap.kt`. AnkiDroid 2.25.3 has
  no direct `SingleAxisDetector` unit test; Android `MotionEvent` extraction is
  outside this model.
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
`BindingMapTest.kt`, and applicable `BindingAndroidTest.kt` cases, including
the projected key dispatch behavior in `Binding.kt` and `BindingMap.kt`.
They are not a port of the Android test harness.
