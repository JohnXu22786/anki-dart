# Notices

This repository contains a partial, modified Dart port of code from
[AnkiDroid](https://github.com/ankidroid/Anki-Android), release 2.25.3, commit
`d9bf072f814a0c37d30a694192593b31ff2df875`. It is an independent project and
does not imply endorsement by the AnkiDroid or Anki projects.

## Adapted source

- `AnkiDroid/src/main/java/com/ichi2/anki/deckpicker/DeckFilters.kt` is
  Copyright © 2026 Arthur Milchior <arthur@milchior.fr>. Its Dart adaptation is
  `lib/src/deck_filters.dart`, with locale-sensitive case handling in
  `lib/src/locale_lowercase.dart`.
- `AnkiDroid/src/main/java/com/ichi2/anki/deckpicker/DisplayDeckNode.kt` is
  Copyright © 2025 Gautam Bhetanabhotla <gautamarcturus@gmail.com>. Its Dart
  adaptation is `lib/src/display_deck_node.dart`.
- `AnkiDroid/src/main/java/com/ichi2/anki/dialogs/ChangeNoteTypeViewModel.kt`
  is marked `GPL-3.0-or-later` and attributes source copyright to Hari
  Srinivasan. Its pure regular/cloze conversion-direction mapping and default
  field-map and discarded-field projections are adapted in
  `lib/src/change_note_type_conversion.dart`,
  `lib/src/change_note_type_default_field_map.dart`, and
  `lib/src/change_note_type_discarded_fields.dart`; the template-mapping
  default template mapping is in `lib/src/change_note_type_default_template_map.dart`; user
  update projections are in `lib/src/change_note_type_template_mapping_update.dart`
  and `lib/src/change_note_type_field_mapping_update.dart`. The pure `hasChanges`
  decision is in `lib/src/change_note_type_has_changes.dart`; discarded template
  projection is in `lib/src/change_note_type_discarded_templates.dart`. Collection/type
  lookup, state flow, template UI, note conversion, and sync behavior are not
  included.
- `libanki/src/main/java/com/ichi2/anki/libanki/sched/DeckNode.kt` is Copyright
  © 2020 Arthur Milchior <arthur@milchior.fr>. Its Dart input projection and
  `totalCardsDue()` behavior are in `lib/src/deck_node.dart`; the total sums
  immediate child aggregates as used by `DeckPickerViewModel.kt`, preserving
  Kotlin signed 32-bit `Int` overflow behavior. When omitted, the synthetic
  flag is derived from projected depth (`depth < 0`), matching the source's
  `node.level <= 0`; explicit Dart overrides remain available.
- `AnkiDroid/src/main/java/com/ichi2/anki/ui/windows/reviewer/ReviewerViewModel.kt`
  is marked `GPL-3.0-or-later` in its upstream header. Its reviewer action and
  queue lifecycle, including the current-card mutation readiness barrier and
  retaining a non-null post-hook queue state before answer reveal, grading from
  the post-hook state, and the last-published StudyCounts snapshot across
  timebox/loading/completion, is adapted by `lib/src/review_session.dart`; the
  upstream file does not state an individual copyright holder.
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
  `lib/src/review_presentation.dart`. The source's default count/active-queue
  values and last-published snapshot behavior are modeled in
  `lib/src/review_session.dart`; the Android view widgets are not included.
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
  `lib/src/previewer_navigation.dart`. Its flag codes and set/toggle choice with
  ordered write-then-publish-on-success effects are adapted in
  `lib/src/previewer_flag_effects.dart`; collection/undo execution, current-card
  lookup and StateFlow publication remain outside.
- `AnkiDroid/src/main/java/com/ichi2/anki/cardviewer/CardAppearance.kt` and
  `AnkiDroid/src/main/java/com/ichi2/anki/reviewer/ReviewerCustomFonts.kt`
  are part of the GPL-3.0-or-later AnkiDroid source. Their CSS zoom appending,
  exact OpenSans CSS prefix composition, bold-weight string replacement, and
  class suffix/card-class projections are adapted in
  `lib/src/card_appearance_css.dart`, reusing the internal Java Float formatter
  in `lib/src/java_float_format.dart`. The host supplies font scale, zoom
  preferences, current-theme projection, and centering state. Font resource
  installation/selection, theme selection/preferences/CSS, vertical-centering
  styles, AndroidCardRenderContext audio and MathJax rendering, WebView
  textZoom, and full rendering remain outside. The pinned test tree has no direct
  assertions for `ReviewerCustomFonts.updateCssStyle()`,
  `CardAppearance.fixBoldStyle()`, `getCssClasses()`, or `getCardClass()`; those
  Dart cases are source-derived. The upstream `ReviewerCustomFonts.kt` header
  attributes Copyright © 2013 Flavio Lerda <flerda@gmail.com>.
- `AnkiDroid/src/main/java/com/ichi2/anki/cardviewer/CardTemplate.kt`
  declares `GPL-3.0-or-later`. Its first-marker section segmentation and ordered
  HTML-string composition, including the `RenderedCard` value, are adapted in
  `lib/src/card_template.dart`. A missing style marker retains the uncaught
  negative-`take` argument failure as Dart `ArgumentError`; invalid later
  boundaries map to `StateError` with the pinned source message. The pinned
  `CardTemplateTest.kt` directly covers canonical replacement and a 1,000-
  character insertion; malformed-marker cases are source-derived. The host
  supplies the template string; Android asset loading, full card rendering and
  media-reference expansion, and WebView integration remain outside this
  slice. Resolved sound markup is separately listed below.
- `AnkiDroid/src/main/java/com/ichi2/anki/cardviewer/AndroidCardRenderContext.kt`
  declares `GPL-3.0-or-later`. Its private `enrichWithQADiv()` string wrapper is
  adapted as `wrapCardContentInQaDiv()` in `lib/src/card_template.dart`; content
  is inserted verbatim between the exact source tags. The pinned tests do not
  directly cover this private helper, so Dart assertions are source-derived.
  Android-side filtering, full media-reference expansion, bold rewriting,
  rendering, and caller orchestration remain outside this slice. Resolved
  sound markup is separately listed below.
- `AnkiDroid/src/main/java/com/ichi2/anki/multimedia/SoundUtils.kt` is
  Copyright © 2009 Edu Zamora <edu.zasu@gmail.com> and © 2014 Timothy rae
  <perceptualchaos2@gmail.com>, and is marked GPL-3.0-or-later. Its source
  audio-button and video-element string projections for already-resolved media
  references are adapted in `lib/src/card_media_markup.dart`. The host supplies
  the audio/video kind, play side/index, video URI, and HTML-escaped filename;
  reference parsing/replacement, media-type and file resolution, playback, and
  WebView integration remain host-side. `libanki/Sound.kt` contains separately
  AGPL-incorporated parser code and is not adapted by this module.
- `AnkiDroid/src/main/java/com/ichi2/anki/cardviewer/TypeAnswerModifiers.kt`
  declares `GPL-3.0-or-later`. Its source-prefix parsing and four-field value
  semantics are adapted in `lib/src/type_answer_modifiers.dart`; field lookup,
  cloze-content invocation, answer comparison, template rendering, and Android
  input integration are not included.
- `AnkiDroid/src/main/java/com/ichi2/anki/previewer/TypeAnswer.kt` declares
  `GPL-3.0-or-later`. Its `removeTags` regex behavior is adapted as the pure
  question-side `removeTypeAnswerTags` function in `lib/src/type_answer_tags.dart`.
  Previewer integration, field lookup, answer comparison,
  rendering, and Android input remain outside this port.
- `AnkiDroid/src/main/java/com/ichi2/anki/cardviewer/TypeAnswer.kt` declares
  `GPL-3.0-or-later`. Its question-prompt transformation in `filterQuestion`
  is adapted as `filterTypeAnswerQuestion` in
  `lib/src/type_answer_question.dart`. The host supplies the extracted prompt
  state. Its `filterAnswer` placeholder replacement is adapted as
  `filterTypeAnswerAnswer` in `lib/src/type_answer_answer.dart`; the host
  supplies already-computed comparison HTML. Its pure `contentForCloze`
  extraction is adapted as `typeAnswerContentForCloze` in
  `lib/src/type_answer_cloze.dart`; its `updateInfo` marker-to-index projection
  is also adapted there as `typeAnswerDeclarationForQuestion` and
  `typeAnswerClozeIndexForQuestion`. The host supplies the rendered question,
  card ordinal, and field text. The Rust comparator,
  card/template and answer lookup, Android state delivery, cloze-content
  invocation, Android input lifecycle and JavaScript integration, and card
  rendering remain outside this port. The `updateInfo` field/result decision is
  adapted as `resolveTypeAnswerFieldResult` in
  `lib/src/type_answer_field_result.dart`; the host supplies ordered field
  metadata, note values, cloze index, and already-localized warnings. The
  projection preserves first exact-name match, copied font/size/language hint,
  no-match metadata retention, and the source's distinct warning behavior for
  null, empty, and nonempty results. Field lookup, warning localization, and
  state delivery remain host-side. The full pure `updateInfo` branch/effect
  order is projected as `planTypeAnswerInfoUpdate` in
  `lib/src/type_answer_info_update.dart`; the host applies the assignments in
  order and handles Android/collection/resource access and source-equivalent
  failure delivery. The pinned test tree has no direct `updateInfo` test.
  The pure `validForEditText` and `autoFocusEditText` checks are adapted as
  `typeAnswerValidForEditText` and `typeAnswerAutoFocusEditText` in
  `lib/src/type_answer_eligibility.dart`. They preserve the non-null check
  (including an empty string) and exact `useInputTag`/`autoFocus` gates; the
  host handles field visibility and Android focus/input lifecycle. No direct
  pinned tests cover these predicates.
- `AnkiDroid/src/main/java/com/ichi2/anki/browser/BrowserColumnCollection.kt`
  and `CardBrowserColumn.kt` declare `GPL-3.0-or-later`. Column-key parsing,
  load-time fallback/de-duplication, nullable updates and replacement are
  adapted in `lib/src/browser_column_collection.dart`; successful updates can
  retain duplicates until a later load removes them, as in the source. The host
  supplies the current Cards/Notes mode, and the same file maps all column types
  from `CardBrowserColumn.kt`, including `template` as TEXT for Cards and
  NUMERIC for Notes and `cardDue` as UNSPECIFIED. Mode/config lookup, mode-specific
  defaults from `BrowserConfig.kt` (whose constants incorporate upstream AGPL
  code and are not copied), SharedPreferences, labels/tooltips, backend column
  values and browser UI remain outside.
- `AnkiDroid/src/main/java/com/ichi2/anki/browser/BrowserColumnSelectionAdapter.kt`
  and `AnkiDroid/src/main/java/com/ichi2/anki/utils/ext/MutableList.kt` declare
  `GPL-3.0-or-later`; their row movement-capability and adjacent-swap plan are
  adapted in `lib/src/browser_column_selection_move.dart`. It preserves the
  literal target-position-zero guard and accepted same-position no-op; the host
  applies swaps and handles RecyclerView notifications, drag lifecycle and the
  column-selection UI.
- `AnkiDroid/src/main/java/com/ichi2/anki/browser/BrowserColumnSelectionAdapter.kt`
  and `BrowserColumnSelectionFragment.kt` declare `GPL-3.0-or-later`. The pure
  click-toggle target/side projection is adapted in
  `lib/src/browser_column_selection_toggle.dart`: it locates the first
  AVAILABLE heading in the host-projected row kinds, preserves the source's
  `< heading` side test, and applies the original-index remove-then-insert move
  without validation. If the heading is missing, insertion uses `-1` and can
  fail after removal, as in the source. Android click wiring, RecyclerView
  notifications, and dialog lifecycle remain host-side.
- `AnkiDroid/src/main/java/com/ichi2/anki/browser/BrowserColumnSelectionFragment.kt`
  and `CardBrowserViewModel.kt` declare `GPL-3.0-or-later`. Their pure save
  decision is adapted in `lib/src/browser_column_selection_save.dart`: it
  preserves the ordered-list comparison, the pre-update dismissal when there
  are no changes, the unconditional update call, and the later success-dismiss
  or failure-message result. Thus the source's no-change fall-through can
  produce an initial dismissal followed by the no-columns message. Preference
  and backend updates, Android dialog lifecycle, and localized snackbar
  delivery remain host-side. No direct pinned save-handler test was found;
  Dart coverage is source-derived.
- `AnkiDroid/src/main/java/com/ichi2/anki/browser/BrowserColumnSelectionFragment.kt`
  and `AnkiDroid/src/main/java/com/ichi2/anki/dialogs/DiscardChangesDialog.kt`
  declare `GPL-3.0-or-later`. The pure Back/discard projection is adapted in
  `lib/src/browser_column_selection_discard.dart`: the host supplies the current
  discard-callback enabled state, and the plan distinguishes default Back
  handling from opening the discard dialog. A positive confirmation emits
  disable-guard then redispatch-back effects in source order; cancellation
  emits none. The Android dispatcher, dialog callback/lifecycle and delivery
  remain host-side. No direct pinned Back-flow test was found; Dart coverage is
  source-derived.
- `AnkiDroid/src/main/java/com/ichi2/anki/browser/BrowserColumnSelectionAdapter.kt`
  declares `GPL-3.0-or-later`. Its pure displayed/available/selected row
  projection is adapted in `lib/src/browser_column_selection_projection.dart`:
  the first Available heading determines the strict index split, heading rows
  are excluded, and a missing heading preserves the source `-1` behavior.
  Labels/samples, RecyclerView state and notifications, saving, and state
  restoration remain host-side. The pinned screenshot and touch-helper tests do
  not directly assert these getters; Dart coverage is source-derived.
- `AnkiDroid/src/main/java/com/ichi2/anki/browser/CardOrNoteId.kt`,
  `AnkiDroid/src/main/java/com/ichi2/anki/browser/BrowserRowCollection.kt`, and
  `AnkiDroid/src/main/java/com/ichi2/anki/model/CardsOrNotes.kt` declare
  `GPL-3.0-or-later`. Their Cards/Notes-associated row ID and collection
  projections are adapted in `lib/src/browser_row_collection.dart`. The host
  supplies collection callbacks for card-to-note and note-to-card lookups. The
  port preserves the source's note-ID snapshot before asynchronous note-to-card
  expansion even if the aliased row list changes while lookups are pending.
  Empty Notes-row queries return an empty list without invoking or requiring the
  lookup callback, as the pinned source's list transforms do not invoke their
  lambdas for an empty row list; nonempty row lookups remain host-side. Android
  collection access, backend row data, and sorting are not included.
- `AnkiDroid/src/main/java/com/ichi2/anki/browser/CardBrowserViewModel.kt` and
  `common/src/main/java/com/ichi2/anki/common/utils/ext/List.kt` declare
  `GPL-3.0-or-later`. `browserRowPositionOfId()` in
  `lib/src/browser_row_collection.dart` adapts the first-match index-or-null
  lookup; Android scrolling, notifications, and layout offsets remain host-side.
- `AnkiDroid/src/main/java/com/ichi2/anki/browser/CardBrowserFragment.kt`
  declares `GPL-3.0-or-later`. `browserPaneRowNotificationPositions()` in
  `lib/src/browser_row_collection.dart` adapts its ordered, distinct pane-row
  lookup to current adapter positions; pane-state mutation and Android adapter
  notifications remain host-side.
- `AnkiDroid/src/main/java/com/ichi2/anki/browser/CardBrowserViewModel.kt`
  declares `GPL-3.0-or-later`. Its `RowSelection` value and selected-row toggle
  state projection are adapted in `lib/src/browser_row_selection.dart`, which
  retains source insertion order, mode-change causes, last-selected ID, and
  refresh behavior. Upstream `CardBrowserViewModelTest.kt` directly exercises
  multi-select tap outcomes; the pure value-projection cases are source-derived.
  Its `onTap` branch and `setNoteEditorRow` effect order are projected by
  `lib/src/browser_row_activation.dart`: normal taps route to a pane or
  activity, while only deselecting an already selected row in fragmented mode
  adds a pane reload after the selection toggle. Upstream
  `CardBrowserViewModelTest.kt:1395–1472` directly covers the major tap
  branches. The host applies Android flows, selection widgets, pane/mode state,
  collection-backed destination lookup, and note-editor commands.
  Its `toggleMark()` all-or-none target decision is projected by
  `planBrowserBulkMarkToggle()` in `lib/src/browser_bulk_mark.dart`: no selected
  card IDs means no operation; otherwise any unmarked note selects adding the
  `marked` tag, while all marked notes select removal. The source's empty-note
  `all()` behavior is retained. `CardBrowserViewModelTest.kt:792–804` directly
  covers adding the mark to unmarked notes with selection retained; other
  branch/edge cases are source-derived. Note/tag lookup, undoable collection
  mutation, and post-success card-state flow publication remain host-side.
  Its `toggleBury()` decision and `BuryResult` values are projected by
  `planBrowserBulkBuryToggle()` and `BrowserBulkBuryPlan` in
  `lib/src/browser_bulk_bury.dart`. The source tests cover the main single/mixed
  branches, no-selection behavior, and manual-buried queue change; sibling
  burial, empty resolved IDs and projection-value checks are source-derived.
  The host checks selection before resolving card IDs, maps queue states,
  performs the undoable scheduler operation, and exposes the result only after
  success.
  Its `toggleSuspendCards()` all-or-none decision is projected by
  `planBrowserBulkSuspendToggle()` and `BrowserBulkSuspendOperation` in
  `lib/src/browser_bulk_suspend.dart`: all selected card queues must be
  `Suspended` to select unsuspending; a mixed or unsuspended set selects
  suspending. The source's empty `all()` behavior is retained. Direct
  `CardBrowserViewModelTest.kt:662–749` cases directly exercise no-selection,
  all-suspended, mixed, and none-suspended behavior in Cards mode and
  no-selection/all-suspended/mixed behavior in Notes mode; the later
  none-suspended Notes helper is not annotated as a test. Queue-projection
  order and empty resolved IDs are source-derived. The host
  checks row selection before resolving card IDs, performs queue lookup and the
  selected scheduler call inside its undoable operation, and owns execution.
  Its `prepareToRepositionCards()` partition and `canRepositionCard()` rule are
  represented by `planBrowserRepositionCards()` and `BrowserRepositionPlan` in
  `lib/src/browser_reposition_plan.dart`. Host-resolved type-New or queue-New
  cards remain eligible; both eligible and skipped IDs preserve selected-row
  order, and skipped count is exact after a full scan. The pinned tests directly
  cover mixed New/Review count, all-New, suspended-New eligibility, and the
  all-ineligible error (`CardBrowserViewModelTest.kt:1063–1147`); order and
  queue-only eligibility cases are source-derived. The host resolves selected
  card IDs and queue/type state, scans the collection, computes queue bounds,
  applies scheduler defaults, and performs or reports repositioning.
  `projectBrowserRepositionPresentation()` and its typed resource/directive
  values in `lib/src/browser_reposition_presentation.dart` map the fragment's
  error, missing-bound, and valid-bound result branches. The upstream ViewModel
  tests cover source request results and bounds, but no pinned test directly
  asserts the fragment's presentation branches; the Dart mapping tests are
  source-derived. Resource resolution, task launching, actual UI construction
  and delivery, and repositioning remain host-side.
  `RepositionData` min/max normalization is represented by
  `BrowserRepositionQueueBounds` and `projectBrowserRepositionQueueBounds()` in
  `lib/src/browser_reposition_queue_bounds.dart`: two present values are
  ordered into top/bottom, while either missing value clears both; equal and
  negative values are retained. ViewModel integration tests cover normal bounds
  for regular and suspended-new cards, but not the constructor directly;
  reversed/equal/negative/null cases are source-derived. SQL lookup and the
  source `max(0,minDue)` behavior remain host-side.
  The host-read due extrema mapping at `CardBrowserViewModel.kt:1125–1138` is
  projected by `projectBrowserRepositionDueExtrema()` in
  `lib/src/browser_reposition_due_extrema.dart`: only minDue is clamped to zero,
  maxDue is preserved, and the result reuses the queue-bounds projection. SQL
  and cursor work, scheduler defaults and execution remain host-side. The pinned
  ViewModel test covers ordinary positive values; negative min/max cases are
  source-derived.
  `requestChangeNoteType()` at `CardBrowserViewModel.kt:383–394` is represented
  by `planBrowserChangeNoteType()` and `BrowserChangeNoteTypePlan` in
  `lib/src/browser_change_note_type_plan.dart`. It checks host-supplied note IDs
  against the first selected note type's membership set, then deduplicates
  compatible IDs in selected order. Upstream tests directly cover no selection,
  mixed types, and same-type single/multiple notes; duplicate order and explicit
  membership cases are source-derived. Note-type resolution, collection queries,
  flow publication, snackbar/dialog delivery and the change itself remain
  host-side.
  `CardBrowserFragment.onChangeNoteType()` at `CardBrowserFragment.kt:1225–1230`
  is represented by `projectBrowserChangeNoteTypePresentation()` in
  `lib/src/browser_change_note_type_presentation.dart`: NoSelection has no
  user-visible action, MixedSelection carries the source snackbar resource, and
  ChangeNoteType carries the response IDs unchanged to a dialog directive. No
  pinned test directly invokes the Fragment presenter; the ViewModel tests cover
  response values, while these mappings are source-derived. Logging, flow
  collection, resource/UI work and subsequent note-type change remain host-side.
  `toHumanReadableContent()` at `CardBrowserViewModel.kt:1794–1798` is adapted
  by `projectBrowserRepositionSummary()` in
  `lib/src/browser_reposition_summary.dart`: host-supplied localized top and
  bottom lines are joined with one newline, or null is returned if either bound
  is missing. The pinned ViewModel test directly asserts normal summary text;
  missing-bound tests are source-derived. Resource resolution and localization
  remain host-side; this helper has no production caller in the pinned source.
  Its `updateSelectedCardsFlag()` write/event/return sequence is represented by
  `planBrowserSelectedCardsFlagUpdate()` and `BrowserSelectedCardsFlagPlan` in
  `lib/src/browser_selected_flag_plan.dart`. The host supplies selected card
  IDs and the source flag value; the plan preserves that list and flag, orders
  the write before card-state-changed publication, and retains the source's
  no-guard behavior for an empty list. No pinned test directly covers this
  method, so these Dart cases are source-derived. The host resolves IDs,
  performs the undoable write, delivers the event only after success, and
  returns the IDs after the sequence completes.
  `selectAll()`, `selectNone()` and `toggleSelectAllOrNone()` are projected by
  `BrowserBulkSelectionTransition` and the `planBrowserSelect*` functions in
  `lib/src/browser_row_selection.dart`. Select-all appends new distinct rows in
  linked-set order and emits the source multi-select `Other` cause before row
  refresh; select-none copies previous IDs, clears the rows, and refreshes while
  retaining multi-select mode. The toggle follows the current cached
  SELECT_ALL/SELECT_NONE state supplied by the host. The pure
  `projectBrowserSelectAllOrNoneState()` also applies the source visible-row
  rule, direct `>= rowCount` comparison, and initial SELECT_NONE value. The
  pinned `CardBrowserViewModelTest.kt:1316–1329,1361–1375` covers initial,
  partial, full and mode-integrated outcomes; hidden-selection, duplicate-ID,
  zero/negative-count projection cases and immutable projection/no-op/effect-
  order assertions are source-derived. The source mutates its synchronized set
  in place; the pure Dart results are ordered immutable snapshots. Row loading,
  StateFlow scheduling/coroutine delivery, and selection widgets remain
  host-side.
  `selectedNoteCount()` at `CardBrowserViewModel.kt:931` applies
  `distinct().size` to note IDs from `BrowserRowCollection.queryNoteIds()`,
  represented by `browserSelectedNoteCount()` in
  `lib/src/browser_row_selection.dart`. The host supplies IDs after the
  Cards/Notes collection lookup. No pinned test directly exercises the count;
  the Dart empty/duplicate/unique-ID cases are source-derived. The localized
  delete-menu plural and UI remain host-side.
  `hasSelectedAllDecks()` at `CardBrowserViewModel.kt:933–935` is represented by
  `browserHasSelectedAllDecks()` in `lib/src/browser_search_request.dart`; it
  returns true only when the deck-filter list is empty and ignores other filter
  fields and available rows. Direct ViewModel tests at
  `CardBrowserViewModelTest.kt:274–290,1531–1574` cover its selected-deck and
  search-result use; the Dart unrelated-filter case is source-derived. Current
  search-flow values, result-message delivery, localization, and UI stay
  host-side.
  `querySelectionExportData()` is projected by `planBrowserSelectionExport()`
  and `BrowserSelectionExportPlan` in `lib/src/browser_selection_export.dart`.
  It returns no plan for an empty selected set; otherwise it chooses Cards or
  Notes export type from the supplied mode and copies raw row IDs in linked-set
  iteration order. Direct `CardBrowserViewModelTest.kt:761–790` covers the
  empty, one-card, and one-note cases; ordering and list-copy checks are
  source-derived. The host handles the export dialog, cache/file preparation,
  and actual export; this port does not implement export formats or execution.
  `setFlagFilter()` at `CardBrowserViewModel.kt:1236–1245` builds a legacy
  `flag:<code>` query from the current search terms; the pure transformation is
  represented by `browserSearchTermsWithFlag()` in
  `lib/src/browser_flag_filter_query.dart`. It preserves the source's
  case-sensitive substring check, first unanchored `flag:.` replacement,
  one-character consumption, nonempty-query prepend, and unmatched incomplete-
  marker behavior. `Flag.kt` source values supply the integer code to the host.
  `CardBrowserViewModelTest.kt:293–307` tests RED filtering end-to-end but does
  not assert the constructed text, so string boundary cases are source-derived.
  The host owns flag UI, query submission/flows, and backend search.
  `libanki/src/main/java/com/ichi2/anki/libanki/Consts.kt` is Copyright (c) 2014
  Houssam Salem and is licensed GPL-3.0-or-later; the host maps its
  `QueueType.Suspended` identity to the headless enum.
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
- `AnkiDroid/src/main/java/com/ichi2/anki/browser/CardBrowserLaunchOptions.kt`
  and the related extra names in `CardBrowserViewModel.kt` are declared
  `GPL-3.0-or-later`. Their ordered deep-link, JavaScript-search, card-ID, and
  process-text option projection is adapted in
  `lib/src/browser_launch_options.dart`. The host supplies already-decoded
  values; Android Intent/Uri access and navigation remain outside.
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
  access, backend query generation, and execution are not included. The Dart
  `BrowserNoteTypeNameId` constructor is intentionally non-const so equal-field
  instances retain identity semantics rather than Dart const canonicalization;
  callers should construct ordinary mapping instances. No pinned test directly
  checks this equality rule; the added assertion is source-derived. The view
  model's `FilterUpdate` origin and one-snapshot request projection are adapted
  in `lib/src/browser_filter_update.dart`; StateFlow/coroutine timing and
  application of field-specific setter updates remain with the host. The four
  Card Browser filter setter projections in that file preserve the source
  `SearchFilters.copy(field = incomingList)` behavior: each returns a User
  update without equality suppression, retains the incoming list reference,
  and reuses other field lists. `SearchFiltersTest.kt` does not directly test
  the ViewModel setters, so the new setter cases are source-derived. The
  Basic/Advanced text buffers and transition methods are adapted in
  `lib/src/browser_search_text_state.dart`; SavedStateHandle persistence,
  flow scheduling, and Android text widgets remain with the host.
  The ordered `onSearchTextChanged` effects are projected in
  `lib/src/browser_search_state_effects.dart`: a shallow-copied User filter
  update precedes text replacement in the active buffer. LF is replaced while
  CR and other characters remain unchanged; no request or close event is
  emitted. The pinned text tests do not assert this combined effect order, so
  the corresponding Dart cases are source-derived.
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
  delivery remain with the host. `submitSavedSearch`'s direct filter/text/close
  effect sequence is adapted in `lib/src/browser_search_state_effects.dart`;
  the downstream closed-screen search flow, request generation, and history
  effects remain separate host-applied behavior.
- Behavioral cases in `test/deck_filters_test.dart` are adapted from
  `DeckFiltersTest.kt`, Copyright © 2026 Arthur Milchior.
- Behavioral cases in `test/deck_list_test.dart` are adapted from
  `DeckNodeTest.kt`, Copyright © 2025 Shridhar Goel.
- The same Dart tests include source-derived empty-child and signed
  overflow/underflow cases; the pinned `DeckNodeTest.kt` does not directly test
  those boundaries or directly assert `depth`/`isSyntheticDeck`. Synthetic
  constructor parity cases are source-derived from `DeckNode.kt`'s level
  projection.
- `test/review_session_test.dart` checks the reviewer flow recorded in
  `ReviewerViewModel.kt`, `Scheduler.kt`, and `Collection.kt`; it is not a port
  of the Android test harness. The post-hook queue-state-on-reveal and
  count-snapshot retention cases are source-derived because the pinned tests do
  not directly assert those behaviors.
- `test/review_timebox_test.dart` checks the strict threshold, zero disablement,
  result payload, answer delta, restart reads, negative-limit behavior, and
  rounded-minute conversion from `Collection.kt` and `ReviewerFragment.kt`;
  there is no direct upstream `timeboxReached()` unit test, and this is not a
  port of the Android test harness.
- `test/previewer_navigation_test.dart` adapts the navigation cases in
  `PreviewerViewModelTest.kt`; it does not port the Android test harness,
  collection, or card-rendering setup.
- `test/previewer_flag_effects_test.dart` adapts the Previewer flag toggle case
  and adds source-derived checks for all flag codes, toggle decisions, and
  write/publish ordering. The pinned test covers RED set/toggle only; no direct
  test covers every code or failed collection writes.
- `test/type_answer_modifiers_test.dart` adapts all direct parser cases in
  `TypeAnswerModifiersTest.kt` and adds source-derived checks for unknown-prefix
  stopping, verbatim remainder handling, empty input, and structural equality.
  It does not port card/note lookup or rendered TypeAnswer behavior.
- `test/type_answer_tags_test.dart` contains source-derived checks for the
  `TypeAnswer.removeTags` regex. `TypeAnswerTest.kt` has related answer-side
  placeholder cases but no direct `removeTags` test; answer-side behavior is not
  claimed as ported here.
- `test/type_answer_question_test.dart` contains source-derived checks for
  `TypeAnswer.filterQuestion`, including prompt formatting and Java Matcher
  replacement strings. The pinned `TypeAnswerTest.kt` has no direct
  `filterQuestion` tests; its answer-filter cases are only adjacent evidence.
- `test/type_answer_answer_test.dart` contains source-derived checks for the
  placeholder-substitution stage of `TypeAnswer.filterAnswer`. The pinned
  `TypeAnswerTest.kt` directly tests full answer filtering with
  `CollectionManager.compareAnswer`; it does not isolate this substitution
  stage. Dart accepts the comparator's HTML as input and does not port the
  comparator or Android integration.
- `test/type_answer_cloze_test.dart` adapts the two direct assertions in
  `TypeAnswerTest.kt` for repeated and distinct cloze answers, and adds
  source-derived cases for hints, no matches, requested index, order,
  duplicates, malformed payloads, and line boundaries. The pinned suite has no
  direct `updateInfo` cloze-index test; source-derived cases cover modifier
  parsing, first-marker/absent-marker behavior, Java line terminators,
  signed-32-bit ordinal overflow, and the -1-to-zero edge. Card/template
  lookup, ordinal extraction, state updates and cloze-content invocation remain
  host-side.
- `test/type_answer_field_result_test.dart` contains source-derived checks for
  `TypeAnswer.updateInfo` field selection/result behavior; the pinned test tree
  has no direct test for this method. Host lookup, localization and state
  application remain excluded.
- `test/type_answer_info_update_test.dart` contains source-derived checks for
  the ordered `TypeAnswer.updateInfo` branch/effect plan, including early
  return, metadata and warning transitions, and the lookup-failure boundary.
  The pinned test tree has no direct `updateInfo` test; Android state delivery,
  resources, collection access and exception application remain host-side.
- `test/type_answer_eligibility_test.dart` contains source-derived checks for
  the exact `validForEditText`/`autoFocusEditText` boolean decisions, including
  the source's empty-but-non-null answer case. The pinned suite has no direct
  predicate tests; Android visibility and focus integration remain host-side.
- `test/browser_column_collection_test.dart` adapts the active-column collection
  cases in `BrowserColumnCollectionTest.kt`, including constructor aliasing
  and cached count, and adds a source-derived snapshot key-projection check; it
  does not port SharedPreferences, backend column setup, or the Android harness.
- `test/browser_column_selection_move_test.dart` contains source-derived
  movement eligibility, target-zero rejection, adjacent-swap order, same-position
  and index pass-through assertions based on `BrowserColumnSelectionAdapter.kt`
  and `MutableList.kt`. `BrowserColumnSelectionTouchHelperCallbackTest.kt` tests
  RecyclerView drop-refresh timing, not the move guard or swap order.
- `test/browser_column_selection_toggle_test.dart` contains source-derived tests
  for active/available side selection, first-heading target selection,
  remove-then-insert ordering, the missing-heading partial-mutation edge, and
  invalid source positions. No pinned test directly asserts click toggling;
  the upstream touch-helper test covers drag refresh and the screenshot tests
  cover layout only.
- `test/browser_column_selection_save_test.dart` contains source-derived tests
  for the staged save/dismiss decision, including the unchanged-selection
  fall-through and update-result mapping. The pinned fragment marks saving as
  needing a test; screenshot coverage is not a save-handler test.
- `test/browser_column_selection_discard_test.dart` contains source-derived
  checks for default Back when the discard guard is disabled, confirmation
  when enabled, ordered guard-disable/back-redispatch after confirmation, and
  no callback effects after cancellation. The pinned screenshot test covers
  layout only.
- `test/browser_column_selection_projection_test.dart` contains source-derived
  checks for strict displayed/available boundaries, first matching Available
  heading behavior, usage-row dropping, selected/displayed correspondence, and
  the missing-heading `-1` case. The pinned tests cover screenshots and drag
  callbacks but do not directly assert these adapter getters.
- `test/browser_row_collection_test.dart` contains source-derived checks for
  Cards/Notes row-ID conversion, aliased list replacement/reset, ordered host
  lookups, duplicate-preserving note expansion, and first-card/per-position
  projections. It also checks that empty Notes-row queries do not require a
  host lookup callback; the pinned tests do not directly cover this empty case.
  The upstream `CardBrowserViewModelTest.kt` directly verifies
  expansion of a Notes row to all its cards, and
  `BrowserMultiColumnAdapterRowsTest.kt` exercises reset/replacement through
  the UI adapter; there is no dedicated upstream `BrowserRowCollection` test.
- `test/browser_row_position_test.dart` contains source-derived checks for the
  first duplicate match, `BrowserRowId` value equality, missing IDs, and empty
  rows. The generic pinned `ListTest.kt:11–14` directly covers first-match and
  missing-ID helper behavior, but no upstream test invokes `getPositionOfId`.
- `test/browser_pane_row_notification_test.dart` contains source-derived checks
  for previous/new position order, null and duplicate ID handling, missing-row
  omission, and first matching positions for duplicate rows. Pane-state tests
  exist upstream, but no pinned test asserts the callback's notified positions.
- `test/browser_row_range_test.dart` contains source-derived checks for the
  inclusive row slice, first-match behavior with repeated endpoint IDs, reversed
  endpoints, equal endpoints, and missing-ID index failures. The pinned
  `CardBrowserViewModelTest.kt:489–518` directly
  tests range-selection effects and no repeated emission, but not the ID-based
  range projection.
- `test/browser_preview_starting_index_test.dart` covers no/multi/single
  selection, stale single IDs, and first-match behavior for duplicate browser
  rows. Pinned `CardBrowserViewModelTest.kt:990–1041` directly covers Notes
  preview at zero, Cards with no selection at zero, and single selected Cards at
  positions zero and one; the remaining projection cases are source-derived.
- The same row-collection tests include source-derived concurrent-mutation cases:
  note IDs captured for `queryCardIds` and `queryOneCardIdPerRow` remain fixed
  while the host lookup awaits, matching `BrowserRowCollection.kt` materializing
  `requireNoteIdList()` before expansion. Collection lookups remain host-side.
- `test/browser_row_selection_test.dart` contains source-derived checks for
  selection-toggle order, mode causes, final-row deselection, retained active
  mode after select-none, refresh/last-selected values, and `RowSelection`
  equality. Pinned ViewModel tests cover row selection through UI integration,
  not the pure Dart projection; Android flow delivery and editor/pane actions
  remain outside.
- `test/browser_row_to_edit_test.dart` contains source-derived checks for empty
  row precedence, first-selected-row choice without stale-ID validation,
  multi-select with no selection, and normal-mode first-row choice. Pinned
  `CardBrowserTest.kt:1548–1563,1576–1590` verifies successful editor entry and
  persisted edits, but not the helper's row-choice results.
- `test/browser_toggle_selection_state_test.dart` adapts the initial, partial,
  and fully-selected flow outcomes from `CardBrowserViewModelTest.kt`; its
  hidden-selection, duplicate-ID, and zero/negative-row-count cases are
  source-derived. StateFlow scheduling and UI remain host-side.
- `test/browser_selected_note_count_test.dart` uses source-derived cases for
  empty, repeated, and distinct host-resolved note IDs. No upstream test
  directly asserts `CardBrowserViewModel.selectedNoteCount()`; collection
  lookup and delete-menu plural rendering remain host-side.
- `test/browser_has_selected_all_decks_test.dart` adapts direct ViewModel cases
  for initial/specific-deck false and AllDecks true, plus the search-result
  action branch. The check that non-deck filter fields are ignored is
  source-derived; flow delivery, localization, and UI remain host-side.
- `test/browser_sort_type_test.dart` adapts the sort resolution and save cases in
  `SortTypeTest.kt`, plus typed config fallback behavior from `Config.kt`,
  including the source's global no-sorting behavior; it does not port
  preference/config storage or the Android test harness.
- `test/browser_sort_notification_test.dart` covers the no-ordering variant,
  resolved and fallback label/type values, and both reverse values. The pinned
  `CardBrowserViewModelTest.kt:1951–2003` tests sort query and reverse-direction
  behavior but does not assert notification values; the Dart projection cases
  are source-derived.
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
- `test/browser_search_text_effects_test.dart` adds source-derived cases for
  Basic/Advanced branch selection, LF-only replacement with CR preservation,
  shallow-copy filter/list identity, User-update-before-text order, and absence
  of request/close effects. Pinned tests cover text edits but do not assert this
  combined effect sequence; Android flow execution remains host-side.
- `test/browser_search_state_effects_test.dart` adds source-derived cases for
  `syncState`/`resetSearchState` effect order, verbatim request/filter values,
  and the exact three SavedState keys removed. The pinned source marks reset
  `@NeedsTest("reset")` but has no direct test for either method; host execution
  and coroutine scheduling remain outside this test.
- The same `test/browser_search_state_effects_test.dart` also checks the
  source-derived internal effect order for `submitSavedSearch`. Pinned
  `CardBrowserSearchViewModelTest.kt` directly covers the resulting query text,
  history entry, close event, and submitted search, but does not assert this
  internal order. StateFlow scheduling and downstream request/history effects
  remain host-side.
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
