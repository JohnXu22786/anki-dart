# anki-dart

This repository is an in-progress Dart port of AnkiDroid. Its source baseline
is AnkiDroid **2.25.3** (`v2.25.3`); the exact commit and the files compared so
far are recorded in [ANKIDROID_UPSTREAM.md](ANKIDROID_UPSTREAM.md).

## Current port scope

The current port includes selected source-mapped slices: deck-picker behavior,
the headless review-session lifecycle, reviewer count/next-time presentation
models, the collection timebox counter and rounded-minute projection, Previewer
navigation and flag decision/effect models, Card Browser active-column and sort
preference models, recent-search ordering, JSON serialization, display state,
saved-history request restoration, Cards/Notes row-ID projection/expansion,
row-tap activation directives, bulk mark/bury/suspend decisions, and
selected-card flag update effect plans, all-decks filter state,
selected-row export data, Card Browser flag-filter query text,
structured search-node planning, the
answer-timer state machine,
reviewer Auto Advance, the headless reviewer gesture parser, parsed-gesture
command routing, reviewer binding codec/map and default definitions, headless
reviewer keyboard and axis-button dispatch, answer-button command mapping and
AutomaticAnswer action decoding, and reviewer binding preference/default
resolution and Card Browser launch-option precedence. Card Browser search-text
transitions, text-edit/sync/reset/history-selection/request-submission effect
sequences and saved-search submission effects, saved-search
outcome-message mapping, CardTemplate marker-based string composition and
verbatim card-content QA wrapping,
card-template type-answer modifier parsing, cloze-index derivation and
cloze-content extraction, question-side type-answer placeholder removal,
the host-input field/result decision, and answer-side placeholder
substitution using host-computed comparison HTML.

- Deck-picker search: token and deck-path matching, with locale-invariant query
  casing and locale-aware deck-name casing, including contextual
  and expanding Unicode mappings, Turkish/Azeri/Lithuanian special cases, and
  partial `:` / `::` searches;
- Deck-picker rows and due count: flattening a deck tree into visible rows,
  including ancestor paths, collapsed decks, counts, and selection state, plus
  the source-equivalent total due count across top-level decks, including
  signed 32-bit `Int` overflow behavior. An omitted synthetic-root flag is
  derived from negative depth, matching AnkiDroid's level projection.
- Card Browser columns: `BrowserColumnCollection` recognizes the source column
  keys, loads an ordered `|`-separated value with load-time de-duplication and
  fallback to caller-supplied defaults, and returns serialized update results
  after removing null entries. Successful updates preserve duplicate entries
  until the next load, matching the source method behavior. The host supplies
  mode-specific default keys and persists the returned value; SharedPreferences
  and backend/UI integration stay outside. The constructor keeps the source
  list alias and cached count, while `backendKeys` returns a mapped snapshot.
- Card Browser column types: `BrowserColumn.typeFor(mode)` maps all source
  columns to TEXT, NUMERIC, DATE, or UNSPECIFIED; the `template` column is TEXT
  in Cards mode and NUMERIC in Notes mode. The host supplies the current mode;
  labels, tooltips, backend column data, and mode/config lookup remain outside.
- Card Browser row IDs: `BrowserRowId` associates an ID with Cards or Notes
  mode; `BrowserRowCollection` retains and mutates the supplied list, maps card
  rows to note IDs through a host callback, and expands note rows to cards in
  source order. It snapshots note IDs before asynchronous expansion so later
  row-list mutations do not alter a pending lookup. Per-row selection takes the
  first card, while a note with no cards preserves the source failure. An empty
  Notes-row collection returns an empty result without requiring the host lookup
  callback. Collection lookups remain host-side. Only the
  basic note-to-all-cards behavior has direct upstream integration coverage;
  the dedicated row-collection tests are source-derived.
- Card Browser multi-select toggles: `toggleBrowserRowSelection` projects the
  selected-ID set in insertion order, the `RowSelected`/`DeselectRow` mode
  causes, last-selected row, and the source refresh request. Removing a row
  emits a mode change only when it was the last selected row; adding always
  emits `RowSelected`, including when multi-select was active with zero rows.
  Upstream ViewModel tests cover the add/remove outcomes, while exact value
  projection tests are source-derived. Android flow scheduling, selection
  widgets, destination lookup, and note-editor command delivery remain host-side.
- Card Browser select all/none: `planBrowserSelectAll` and
  `planBrowserSelectNone` preserve linked-set row order and the source's
  no-op-on-no-change behavior. Select-all emits the `Other` multi-select cause
  before row refresh; select-none snapshots then clears selected IDs and keeps
  multi-select active. `planBrowserToggleSelectAllOrNone` follows the cached
  toggle state supplied by the host. `projectBrowserSelectAllOrNoneState`
  projects the source visible-selection rule and `>= rowCount` boundary, with
  the initial `SELECT_NONE` value. Upstream ViewModel tests cover initial,
  partial and full flow outcomes; hidden-selection and zero-count projection
  cases, along with pure transition/effect and no-op assertions, are
  source-derived. StateFlow scheduling, async delivery, and selection widgets
  remain host-side.
- Card Browser selected-note count: `browserSelectedNoteCount` counts distinct
  note IDs after the host resolves selected rows to notes, matching the source
  `.distinct().size` calculation. No pinned test directly covers this count;
  empty, duplicate, and unique-ID assertions are source-derived. Collection
  lookup and the localized delete-menu plural remain host-side.
- Card Browser all-decks state: `browserHasSelectedAllDecks` returns true exactly
  when the deck-filter list is empty, independent of query text, other filters,
  or available rows. Pinned ViewModel tests cover the initial/specific and
  AllDecks states; the Dart check for unrelated filters is source-derived.
  Current search flow, result-message delivery, localization, and UI remain
  host-side.
- Card Browser selected-row export data: `planBrowserSelectionExport` returns
  no data for an empty selection; otherwise it maps Cards/Notes mode to the
  matching export kind and copies IDs in the selected-set iteration order.
  Direct ViewModel tests cover empty selection and one row in each mode; order
  and list-copy cases are source-derived. The host still opens the export dialog
  and handles cache files and actual export.
- Card Browser flag-filter query text: `browserSearchTermsWithFlag` preserves
  the source's first-match `flag:.` replacement, nonempty-query prepend, and
  incomplete-marker behavior. The pinned RED flag test verifies the resulting
  search end-to-end but does not assert the query text; exact string cases are
  source-derived. Android flag actions, query submission, and backend search
  remain host-side.
- Card Browser row activation: `planBrowserRowActivation` returns the source-
  ordered directives for normal phone/tablet editor routing and multi-select
  toggles. A selected row tapped in fragmented mode requests a pane reload only
  after the selection toggle; adding a row or deselecting on a phone has no
  editor effect. Upstream ViewModel tests directly cover the major branches.
  The host resolves collection-backed editor destinations, applies selection,
  pane/mode state, and delivers activity or pane commands; Android row widgets,
  flows, and navigation remain outside.
- Card Browser bulk mark: `planBrowserBulkMarkToggle` returns no operation for
  an empty selected-card list; otherwise it selects tag removal only when every
  resolved note already has `marked`, and selects adding the tag for an unmarked
  or mixed selection. It preserves Kotlin `all(empty)` behavior. The upstream
  ViewModel test directly covers adding the tag to unmarked notes and retaining
  row selection; other decision cases are source-derived. The host resolves
  note/tag state, performs the undoable mutation, and publishes card-state
  refresh only after success.
- Card Browser bulk bury: `planBrowserBulkBuryToggle` returns no plan when no
  rows are selected. Otherwise, it selects unbury only when every selected card
  is manually or sibling buried; any unburied card selects bury. It preserves
  the source action-valued `wasBuried` result, card count, and `all(empty)` case
  for selected rows that resolve to no cards. Upstream ViewModel tests cover
  the main single/mixed and no-selection branches; remaining projection cases
  are source-derived. The host checks selection before resolving card IDs,
  maps queue values, runs the undoable scheduler operation, and exposes the
  result only after success.
- Card Browser selected-card flag updates: `planBrowserSelectedCardsFlagUpdate`
  retains the supplied flag and selected-ID list, then orders the flag write
  before card-state-changed publication and the eventual same-ID return. It
  still plans both effects for an empty ID list. No pinned test directly covers
  `updateSelectedCardsFlag`; these plan assertions are source-derived. The host
  resolves IDs, performs the undoable write, emits the event only after success,
  and returns the IDs after the source sequence completes.
- Card Browser sort choice: `resolveBrowserSortType` reads caller-supplied
  mode-specific config values, checks the key against host-supplied backend
  columns, and returns the source sort type. It defaults missing or
  wrong-typed values to `noteFld` and forward order, treats an unknown column as no ordering, and
  creates ordered save plans without touching Android or collection storage.
  The shared no-sorting flag retains the source's cross-mode behavior.
- Card Browser launch options: `browserLaunchOptionFromInput` selects the first
  host-decoded deep-link search, JavaScript search, card ID, or non-empty
  process-text search in AnkiDroid's source order. Empty deep-link and
  JavaScript query values remain present; the host supplies `all_decks` with a
  false default. Android `Intent`/`Uri` extraction, extra decoding and browser
  navigation remain host-side.
- Card Browser recent searches: `BrowserSearchHistoryModel` keeps searches
  newest-first, promotes structurally equal entries, skips the default blank
  search, and trims history to the source's 30-entry cap.
  `BrowserSearchHistoryJsonCodec` encodes the compact v1/v2 JSON fields in
  source order, omits empty optional arrays, and returns an empty history when
  any decoded entry is invalid. The host handles SharedPreferences. Structured
  saved-entry request restoration uses host-supplied deck/note-type maps.
  `buildBrowserSearchNodePlan` then models the query and ordered filter terms as
  typed nodes, with the source's OR groups, AND root, singleton collapse, and
  explicit flag/card-state mappings. Backend SearchNode conversion, query
  parsing/validation, final SearchString serialization, and execution remain
  outside.
  `BrowserSearchHistoryDisplayModel` starts collapsed, keeps the first five
  entries visible until expanded, and exposes the toggle only above five items.
  It preserves Loading entries with null search strings and Loaded entry/string
  pairs, with source data-class equality/hash behavior; Loading captures its
  null pairs at construction. The host supplies
  converted strings and Android flow/widget integration remains outside.
  `BrowserSavedSearchesModel` applies exact, case-sensitive
  lookup and duplicate handling, Kotlin-compatible query trimming, and map/list
  conversion over a host-supplied config map; collection config IO and the
  saved-search UI remain outside. `browserSavedSearchUserMessageForMutation`
  maps add/delete outcomes to the exact four source message identifiers; the
  host owns localization and message-flow delivery.
  `browserSearchHistoryIsAvailable` checks the supplied history's
  `entryToSearchString` projection (including Loading pairs with null strings),
  and `browserCanManageSavedSearches` checks whether the supplied saved-search
  list is nonempty. The host owns StateFlow updates and availability-dependent
  widgets.
- Card Browser search text: `BrowserSearchTextState` keeps independent Basic and
  Advanced buffers. Mode toggles preserve both, advanced appends follow the
  source's Kotlin-blank and exact trailing-space checks, text edits replace LF
  only in the selected buffer, and saved queries gain one trailing ASCII space.
  Android SavedStateHandle, flow scheduling, text widgets, and saved-search
  lookup remain with the host.
- Card Browser text-edit effects: `browserOnSearchTextChangedEffects` emits a
  shallow-copied User filter update before the LF-sanitized text for the active
  buffer. It preserves every filter list and leaves the inactive buffer alone;
  it does not submit a request or close the screen. Pinned tests cover text
  changes but not this combined effect order, so the ordered-effect tests are
  source-derived. The host applies the effects.
- Card Browser sync/reset: `browserSyncStateEffects` emits the source System
  filter update before submitting the exact request. Reset emits mode, both
  exact text values, System filters, screen closure, and three SavedState key
  removals in source order; it leaves `historyExpanded` untouched. The host
  applies these effects to StateFlows and SavedStateHandle. The pinned source
  marks reset `@NeedsTest("reset")`; neither method has a direct upstream test.
- Card Browser history selection: `browserSelectSearchHistoryEntryEffects`
  emits the source-ordered copied-current User update, LF-sanitized edit to the
  active text buffer, restored User filters, and screen closure. It uses the
  existing first-match deck/note-type ID restoration and falls back to empty
  filters if either map cannot resolve an ID. The host supplies the current
  state and maps and applies the effects; no search request is created or run.
  No pinned test directly covers this selection sequence or host-map
  restoration; the similarly named upstream test calls `submitSearch` instead.
- Card Browser request submission: `browserSubmitCurrentSearchEffects` converts
  the supplied request to a Kotlin-trimmed, ID-based history entry and applies
  `BrowserSearchHistoryModel.addRecent`. It emits the resulting Loading history,
  a close-view event, then the exact request in source order. A blank
  unfiltered request still emits the unchanged history; this overload does not
  set screen-open state. The host persists history, delivers events, and runs
  the search. The pinned view-model tests' `submitSearch` helper calls the
  no-argument overload instead, so these ordered-effect tests are source-derived
  and do not claim direct upstream coverage of the request overload.
- Card Browser saved-search submission: `browserSubmitSavedSearchEffects`
  applies the direct source effects in order: a shallow-copied User filter
  update, LF-sanitized text in the active Basic/Advanced buffer, then screen
  closure. The host's closed-screen flow creates the trimmed request and causes
  the separate history/submission effects. Pinned tests directly check saved
  query text, eventual history, view closure, and submitted search; the Dart
  internal effect-order assertion is source-derived. The host applies the
  effects and owns StateFlow/coroutine scheduling.
- Review session: a headless flow that loads the scheduler's current card, shows
  its question or answer, forwards an Again/Hard/Good/Easy rating, then loads
  the next queue item. It waits for the current card's state-mutation hook
  before revealing or grading it, retains a non-null queue state returned by
  that hook before exposing the answer, reads the queue state again after the
  hook before grading, and pauses for a scheduler timebox event
  before showing the queued card. The previously displayed side remains visible
  during the timebox and while a queue read loads or retries. A failed queue
  read can be retried without sending the completed card's rating again. Its
  separate displayed queue-count snapshot starts at AnkiDroid's 0/0/0, NEW
  defaults and updates only for normal queue states; it stays unchanged during
  timebox, loading, and queue completion, as the source count flow does not emit
  new values there. Count-retention tests are source-derived because the pinned
  suite has no direct timebox count-retention case.
- Timebox counter: adapter callbacks supply integer clock seconds, the configured
  limit, and recorded-answer count. `ReviewTimeboxTracker` preserves the source's
  zero-only disable check, strict elapsed-time comparison, configured-limit
  payload, answer-count delta, and automatic restart. The display model rounds
  seconds to minutes using Float32 division and Kotlin `roundToInt()` behavior;
  localized strings, the Android dialog, and lifecycle wiring remain outside.
- Previewer navigation: `PreviewerNavigationModel` applies the source button
  enablement formulas, next/previous transitions, back-side-only mode, and
  one-based slider selection. It returns a show-side or load-card intent for the
  host to carry out; card lookup, rendering, and media playback remain outside.
- Card appearance projections: `appendCardAppearanceCss` preserves the supplied
  CSS prefix, then appends nondefault font-scale, card-zoom, and image-zoom rules
  in source order with source-compatible numeric formatting.
  `composeCardAppearanceStyle` starts with the exact `ReviewerCustomFonts`
  OpenSans CSS and then appends those rules. `fixCardAppearanceBoldStyle`
  globally changes only the exact `font-weight:600;` substring to
  `font-weight:700;`, matching the Android render caller's post-audio-expansion
  step. The host supplies font scale and zoom preferences.
  `cardAppearanceCssClasses` and `cardAppearanceClassName` project the source's
  class suffixes from host-supplied theme predicates and centering state,
  preserving class spacing/order and direct ordinal interpolation. Font
  resource installation/selection, theme selection and preference IO, actual
  theme CSS, vertical-centering styles, AndroidCardRenderContext's MathJax
  handling, WebView textZoom, and full rendering remain outside.
- Card template strings: `CardTemplate` caches the first style, script, class,
  and content marker positions, then renders the five source-ordered segments
  into a value-equal `RenderedCard`. Later delimiter copies remain literal.
  Missing style maps to Dart `ArgumentError` (the Kotlin negative-`take`
  failure); bad or missing later boundaries map to `StateError` with the source
  message (the Kotlin caught substring failure). This only composes a host-
  supplied template string; Android asset loading, card rendering, media, and
  WebView integration remain outside.
- Card content wrapper: `wrapCardContentInQaDiv` returns the exact source
  `<div id="qa">` prefix, unchanged content, and `</div>` suffix. It does not
  escape or normalize input. Android-side filtering, audio expansion, bold
  rewriting, rendering, and orchestration remain with the host.
- Previewer flags: `PreviewerFlag` preserves the source codes 0–7, and the
  set/toggle projections return a one-card collection-write intent followed by
  publication of the same flag only if the host write succeeds. Current-card
  lookup, the undoable collection operation, asynchronous failure handling and
  StateFlow publication remain with the host. This enum is separate from the
  Card Browser backend search flag values.
- Type-answer modifiers: `TypeAnswerModifiers.parse` consumes repeated leading
  `nosuggest:`, `cloze:`, and `nc:` prefixes in any order and returns the
  unmodified field-name remainder. Field lookup, cloze-content invocation,
  answer comparison, template rendering, and Android input behavior remain
  outside.
- Type-answer cloze index: `typeAnswerClozeIndexForQuestion` finds the first
  source `[[type:...]]` marker in the host-supplied rendered question, parses
  the modifier capture, returns null when no marker matches, zero without
  `cloze:`, or signed-32-bit `cardOrdinal + 1` with `cloze:`. Overflow wraps;
  ordinal -1 produces zero, matching the source's `index != 0` check. The host
  supplies the question and ordinal; card/template access, field lookup,
  warning/state delivery and cloze-content invocation remain host-side. The
  result's warning choice is modeled separately when the host supplies field
  values.
- Cloze content: `typeAnswerContentForCloze` extracts captures for a supplied
  cloze index, cuts each hint at the first `::`, collapses repeated identical
  captures to one value, and otherwise joins all captures in source order.
  The host supplies the already-derived index; card/note lookup and invoking
  this extraction remain host-side.
- Type-answer field result: `resolveTypeAnswerFieldResult` selects the first
  exact field-name match from host-supplied ordered metadata and note values,
  applies the supplied cloze index, and returns the source's answer, matched
  font/size/language metadata, and warning action. No match sets the supplied
  unknown-field or empty-cloze warning without updating metadata; an empty
  answer nulls the answer while preserving the previous warning; a nonempty
  answer clears it. The host performs field/note/resource lookup, warning
  localization, and state delivery. This projection does not parse the
  question marker or obtain a card ordinal.
- Type-answer update effects: `planTypeAnswerInfoUpdate` combines the rendered
  question, card ordinal, ordered field metadata, note values and localized
  warning strings into the source-ordered `updateInfo` assignments. It resets
  combining/no-suggest/correct first, returns after those resets if there is no
  marker, then applies parsed modifiers, answer/cloze selection, metadata and
  the source's warning/empty-answer behavior. A missing selected note value is
  reported after the preceding reset/modifier effects. The host applies the
  plan and performs Android/collection/resource access and failure delivery.
- Type-answer tags: `removeTypeAnswerTags` removes every nonempty, single-line
  `[[type:...]]` match through its first `]]`, preserving other text. This is
  the question-side cleanup model; field lookup, cloze-index invocation,
  answer comparison, rendering, and Android integration remain with the host.
- Type-answer question prompt: `filterTypeAnswerQuestion` applies the exact
  span/input prompt or first warning replacement using host-supplied state.
  Card/note lookup, Android input events and JavaScript integration, and card
  rendering remain host-side.
- Type-answer answer placeholder: `filterTypeAnswerAnswer` replaces every
  matching answer-side placeholder with comparison HTML supplied by the host.
  It preserves the source's case-sensitive, nonempty, lazy single-line match
  and inserts comparison text literally. The Rust answer comparator, answer
  lookup, and Android rendering/input pipeline remain host-side.
- Reviewer presentation: a study-count model that renders the three scheduler
  counts as decimal strings and retains which queue is active, plus an answer
  next-time model that displays the backend's four strings in Again/Hard/Good/
  Easy order without deriving intervals in Dart.
- Answer timer: the hidden/running/paused/stopped model, including card
  configuration, elapsed-time clamping, stop/hide, and lifecycle pause/resume
  transitions. Its state stream replays the current state and conflates rapid
  pending updates like `MutableStateFlow`.
  The host supplies a monotonic millisecond clock corresponding to Android
  `SystemClock.elapsedRealtime()` and calls pause/resume; this model does not
  drive periodic UI ticks or register lifecycle observers.
- Auto Advance: deck-provided question/answer durations and typed actions,
  enable/disable and card-change cancellation, and the `waitForAudio` value
  supplied by an adapter. An injectable delay scheduler supports deterministic
  timing. Same-side visibility events overwrite the tracked job without
  cancelling its earlier timer, matching the pinned source behavior.
- Reviewer gestures: decoded gesture inputs map to two-, three-, and
  four-finger taps, four- or nine-point taps, and directional swipes. The model
  preserves viewport scale and scroll adjustment, strict swipe thresholds,
  scrollable-content suppression, malformed-input callback behavior, and the
  source's asynchronous single/double-tap timing and same-side timer overwrite.
  It retains the zero-valued last-tap sentinel behavior for early event times
  and signed 64-bit timestamp subtraction.
- Gesture command routing: host-supplied gesture bindings resolve to the
  source reviewer command identifiers and declaration order. Later commands
  overwrite duplicate bindings; the four corner taps and center tap depend on
  explicit corner-touch configuration; multi-finger taps remain unmapped. The
  enabled flag affects `isBound` only, and an optional callback receives the
  selected command and gesture. `ReviewerBindingCodec` decodes source-formatted
  serialized strings, and `GestureCommandRouter.fromPreferenceValues` filters
  them to gestures. The host supplies the preference strings; this layer does
  not read Android `SharedPreferences`, receive touch input, or execute reviewer
  actions.
- Reviewer binding preferences: the headless codec preserves `1/` framing,
  `|` list separators, reviewer prefix, gesture enum identifiers, side suffixes,
  permissive reviewer-prefix removal, and the source's unknown-side fallback.
  It represents key-code and Unicode bindings as typed values with source
  modifier parsing and serialization, Kotlin Int32 bounds, UTF-16 code-unit
  selection, and the distinction between deserialization and the guarded
  Unicode factory. `isKey`/validity and reviewer-side serialization are modeled;
  BOTH remains an equality wildcard, and the source's modifier/hash quirks are
  retained. It also validates axis IDs and Java float syntax. Axis values are
  rounded and written using the source's `Float.toString` style, and extra axis
  tokens are ignored like the source parser. Android key events and MotionEvent
  handling are unported.
- Reviewer binding map: `ReviewerBindingMap` consumes explicit typed bindings
  by command; it does not load preferences or implicitly add defaults. It
  keeps every key and gesture registration in action order and per-command
  list order, ignores side when matching while retaining the original side in
  each result, skips unknown bindings, and lists axis registrations
  separately. This differs from `GestureCommandRouter`, whose source-mapped
  behavior lets the later command overwrite a duplicate gesture.
  `ReviewerBindingMap` only returns registrations; Android preferences and
  event decoding remain with the host.
- Reviewer command defaults: `ReviewerDefaultBindings` records each
  `ViewerCommand.defaultValue` list, including empty entries, order, card side,
  and modifiers. Android `KeyEvent.KEYCODE_*` names stay symbolic until the
  host supplies a name-to-integer map to `resolve`. Missing names throw rather
  than dropping a binding. `ReviewerBindingPreferenceResolver` selects these
  defaults only for a null preference. Any present string replaces defaults
  and uses the existing codec, so empty, unsupported-version, and malformed
  values do not fall back. Configured values do not require key-name mappings;
  the host still reads preferences and supplies mappings for default resolution.
- Reviewer answer mappings: `AnswerButtons` maps Again, Hard, Good, and Easy to
  their corresponding `ViewerCommand`. `AutomaticAnswerAction` preserves config
  values 0–4 and the source unknown-value fallback to Bury Card; its reminder
  action has no command. Deck-config access, command execution, logging, and
  localized reminder UI remain with the host.
- Reviewer keyboard dispatch: `dispatchReviewerKeyEvent` consumes a host-
  supplied key event projection and `ReviewerBindingMap`. It ignores repeat
  events, tries a nonzero key code before the precomputed Unicode result,
  constructs candidates with the event's Shift/Ctrl/Alt states, applies
  Kotlin's low-16-bit `Int.toChar` behavior, omits the `|` separator
  candidate, and calls registrations in source order until one returns true.
  Binding lookup keeps source equality behavior, including shift-tolerant
  app-defined Unicode bindings. The adapter computes
  `getUnicodeChar(metaState & (META_SHIFT_ON | META_NUM_LOCK_ON))`; Android
  `KeyEvent` access and keyboard-layout lookup remain outside.
- Reviewer axis-button dispatch: `ReviewerAxisButtonDispatcher` snapshots the
  map's axis registrations and keeps an independent debounce flag for each.
  Positive and negative thresholds compare inclusively; positive and negative
  zero thresholds do not fire. A registration emits once until a nonqualifying
  Float32 sample rearms it. Every registration is evaluated in source order
  even when a processor returns false; the result reports whether any
  registration fired. The host supplies axis values, while Android
  `MotionEvent` extraction and device handling remain outside.

The implementation lives in `lib/` as a Dart library. The review flow requires
a `ReviewScheduler` adapter that supplies queue items, backend counts and active
queue, timebox events, and rating application. Auto Advance requires an
`AutoAdvanceSettingsAdapter` that loads all five settings for the current card's
deck; the model does not read collection storage or supply deck-config defaults.
Its action listener receives a cancellation signal and should observe it while
awaiting work that can be cancelled, matching the source coroutine's cooperative
cancellation.
`PreviewerNavigationModel` consumes the selected-card count and current index
and side flags, then returns an intent for the host to load a card or show a
side. It does not access card IDs, collection storage, or the WebView.
`BrowserColumnCollection` consumes a serialized preference and default keys
from its caller; the host resolves Cards/Notes mode and persists its returned
value. `BrowserColumn.typeFor(mode)` maps the type of every recognized column,
including the source's mode-dependent `template` type and `cardDue`'s
`unspecified` type. The adapter also supplies the mode defaults, so the port
does not copy `BrowserConfig.kt`'s AGPL-incorporated constant definitions.
`resolveBrowserSortType` and `buildBrowserSortSavePlan` consume the shared
no-sorting flag and the active mode's config keys/values from the host. They
also consume the backend's available column keys. The save plan writes the
mode-specific column and reverse keys in source order before clearing the
global no-sorting flag; actual preference/config writes and backend sorting
remain host responsibilities. This keeps `BrowserConfig.kt` key lookup and
its AGPL-incorporated constants outside the Dart port.
`BrowserSearchHistoryModel` consumes and returns the in-memory history list;
`BrowserSearchHistoryJsonCodec` converts that list to and from AnkiDroid's
compact JSON format. `BrowserSearchRequest` restores a structured request using
deck and note-type ID/name mappings supplied by the host and converts requests
back to ID-based history entries. It keeps the stored query unchanged during
restoration and applies Kotlin `String.trim()` when saving a request to history.
Request/filter values preserve source structural equality; note-type map
entries retain identity equality like the upstream regular class. The public
`BrowserNoteTypeNameId` constructor is intentionally non-const because Dart
const canonicalization would merge same-field instances that AnkiDroid keeps
distinct; callers should construct ordinary mapping instances.
The host loads and persists history and resolves current collection objects;
`buildBrowserSearchNodePlan` returns the source-equivalent typed tree before
backend conversion. Backend protobuf SearchNode conversion, query parsing and
validation, final SearchString serialization, query execution, and search UI
stay outside the model. Search text and filters may contain user-provided
data, so storage and privacy handling remain the host's duty.
`BrowserFilterUpdate` models user-versus-system filter origins and the source's
initial empty System state. For one supplied snapshot, its request projection
returns nothing while the screen is open or for a System update; a closed-screen
User update carries the exact filters and Kotlin-trimmed text into a request.
The pure `browserSetDecksFilter`, `browserSetTagsFilter`,
`browserSetCardStateFilter`, and `browserSetFlagsFilter` projections match the
source copy behavior: each returns a User update even for equal values, keeps
the incoming category list, and reuses the other field lists. The host supplies
the snapshot and owns StateFlow/coroutine timing, collection access, and search
execution. The pinned `SearchFiltersTest.kt` covers active-filter presence but
does not directly test these ViewModel setters; their Dart cases are
source-derived.
`BrowserSearchTextState` separately models the Basic/Advanced text buffers:
mode toggles retain both values, Advanced appending uses the source's spacing
rules, text edits replace LF without normalizing CR, and saved-query application
adds one space before taking the same edit path. The host owns
SavedStateHandle persistence, StateFlow scheduling, text widgets, and saved
search lookup.
`browserSyncStateEffects` and `browserResetSearchStateEffects` return typed
ordered effects for synchronization and reset. Reset preserves the submitted
query verbatim, removes only `advancedSearch`, `basicSearchText`, then
`advancedSearchText`, and does not remove `historyExpanded`. The host performs
the flow and SavedStateHandle operations; the pinned source marks reset
`@NeedsTest("reset")` but has no direct reset or sync test.
`BrowserSearchHistoryDisplayModel` separately projects the supplied Loading or
Loaded history into a five-entry collapsed or full expanded list. The host owns
search-string conversion, SavedStateHandle/StateFlow lifecycle, and rendering
the list and expansion toggle.
`BrowserSavedSearchesModel` operates on a host-supplied saved-search config map.
It returns case-sensitive name-sorted values, applies the source duplicate and
query-normalization rules, and exposes map conversion. The saved-search message
projection maps the mutation result's success flag to the source message kind;
the host owns collection config loading/persistence, localized UI message
delivery, and query parsing/execution.
`ReviewNextStateDescriber`
forwards the opaque scheduling state to the pinned backend's
`describeNextStates()` API. The session exposes the timebox's elapsed-time limit
and answer count, and can reload the queue when the caller continues. The
AnkiDroid 2.25.3 source pins
`io.github.david-allison:anki-android-backend` version `0.1.68-anki26.05`; the
Rust backend, collection storage, and scheduling algorithm remain external.
`ReviewTimeboxTracker` consumes clock, configured-limit, and answer-count
callbacks; it does not load settings or collection state. This is not yet a
complete AnkiDroid replacement: Android screens and platform lifecycle integration,
Card Browser Intent/Uri parsing and navigation for mapped launch options,
SharedPreferences and mode lookup, saved-search config IO, localized
outcome-message delivery and UI,
collection-backed deck/note-type lookup, backend query-string generation and
backend SearchNode conversion, query parsing/validation, final SearchString
serialization, search execution, search-string conversion,
Android execution of Card Browser
text-edit/request-submission/sync/reset/history-selection effects and
close-view/submitted-search event delivery,
SavedStateHandle/StateFlow
integration for mode, text buffers, and history/saved-search availability,
Basic/Advanced text widgets, history-list
and toggle widgets,
Card Browser row-selection widgets, StateFlow scheduling/async refresh delivery,
applying row-activation directives,
collection-backed editor destination lookup, and note-editor/pane command delivery,
persistent Cards/Notes mode lookup and AGPL-incorporated column defaults,
collection-backed Card↔Note ID lookups, backend column registry and rows,
column-selection drag/drop and active backend updates, Card Browser sort UI,
Android preference/synced-config IO, and actual backend row sorting,
Previewer SavedStateHandle/card-ID plumbing, collection-backed card loading,
WebView rendering and media, CardAppearance font resource installation and
font-selection preferences, theme selection and actual theme CSS,
vertical-centering preference IO/styles,
MathJax render context, WebView textZoom/lifecycle, previewer
collection flag mutation and StateFlow
publication (flag codes and ordered write/publish intent are modeled), Card
Browser selected-card lookup, collection flag writes and card-state-changed
event execution (the ordered plan is modeled), mark-state lookup, bulk tag and
suspend writes/undo (bulk-mark and bulk-suspend target decisions are modeled),
and note editing, Android card-template asset loading and card content
rendering/media, card/note-dependent TypeAnswer field and note-value lookup
(the field/result projection over supplied values is modeled), rendered-question/
Card.ord extraction and cloze-content invocation (pure cloze-index derivation
and cloze-content extraction are modeled), answer comparison
(placeholder substitution is modeled when comparison HTML is supplied), Android
TypeAnswer input events and JavaScript bridge,
answer-timer widget/tick rendering,
Auto Advance settings
controls and Android preference lookup, `KeyEvent` extraction and hardware/layout
`getUnicodeChar()` calculation, binding display strings, Android
`MotionEvent` extraction and device handling (host-projected axis-button
debounce and dispatch are modeled), host `KEYCODE_*` resolution and preference-
backed value lookup (symbolic defaults and null-versus-configured selection
are modeled), Android
`BindingProcessor` wiring, command execution, touch input and reviewer command handlers,
study-count and answer-button widgets/layout, next-time visibility preference
wiring, template rendering and media, localized timebox messages, dialog and
lifecycle presentation, leech handling, reviewer undo/redo, JavaScript custom-
state and gesture bridges, WebView state collection, Android timeout lookup,
sync, actual import/export, and other app features remain to be ported. The
selected-row export-data projection is modeled, but its dialog, file handling,
and export implementation remain host-side.
The source project has thousands of files, so this repository does not claim
full feature parity.

The port preserves the source behavior for the covered slices, including search
and collapse quirks, recent-search ordering and blank-search suppression,
canonical history JSON field order, omitted defaults and whole-list decode
fallback, the collapsed five-entry history display and untruncated toggle
threshold, saved-search case-sensitive lookup/order, duplicate handling,
Kotlin-compatible query trimming and map conversion, Basic/Advanced buffer
independence, source append spacing, LF-only text replacement, saved-query
trailing spaces, exact ordered sync/reset effects with the intentional
historyExpanded omission, and history-selection effect order including
unresolved-ID fallback, Card Browser bulk suspend's all-selected suspended-queue
decision and empty-ID `all()` behavior,
ordered Card Browser columns and load-time de-duplication,
  sort config defaults (including wrong-typed values), per-mode column values,
  and the global no-sorting quirk,
reviewer action ordering, question/answer transitions, the scheduler timebox
gate, active-count selection, and direct display of backend answer labels. The
answer timer also keeps the source's upper-only elapsed-time
clamp, exact limit comparison, negative elapsed values, and nonpositive-limit
behavior. Scheduling rules remain with the backend. The timebox tracker
consumes adapter-provided values and preserves the source's boundary conditions.
This port does not intentionally correct upstream bugs. See the tests and
upstream mapping for the specific behaviors and source files. Auto Advance
preserves the integer action codes and invalid-code fallbacks, delays and
cancellation boundaries, and the same-side job-overwrite quirk.
An in-flight action listener also receives a cancellation signal when its tracked
job is cancelled; asynchronous adapters must observe it to stop their pending
work, while already-performed synchronous effects remain.
The gesture model also keeps strict grid and diagonal boundaries, Float
threshold and coordinate behavior, and the stale same-side tap job when a
double tap cancels only the latest scheduled job. A canceled delay also
suppresses its pending single-tap callback. The caller supplies tap mode,
swipe sensitivity, and the platform double-tap timeout; the model does not read
Android preferences or WebView properties.

## Use and verify

This package currently contains library code, not a runnable app. It supports
Dart `>=3.11.0 <4.0.0`:

```sh
dart pub get
dart test
```

## License and attribution

The adapted AnkiDroid code is derived from AnkiDroid and is distributed under
**GNU GPL version 3 or, at your option, any later version** (`GPL-3.0-or-later`).
The source repository's root `COPYING` is the GNU GPL version 3 text; the
matching SPDX license text is included at
[`LICENSES/GPL-3.0-or-later.txt`](LICENSES/GPL-3.0-or-later.txt). Copyright and
SPDX notices remain in each adapted Dart source file. See [NOTICE.md](NOTICE.md)
for source-file attribution.

The locale-casing property ranges, lowercase mappings, and BMP decimal-digit
block starts in `lib/src/unicode_15_case_data.dart` are derived from Unicode
15.0.0 UCD data (`UnicodeData.txt`, `PropList.txt`, `DerivedCoreProperties.txt`,
and `SpecialCasing.txt`), Copyright © 2022 Unicode, Inc., and are distributed
under Unicode License V3 (`LicenseRef-Unicode-License-V3`). Its notice is retained
separately in
[`LICENSES/Unicode-License-V3.txt`](LICENSES/Unicode-License-V3.txt); the
AnkiDroid code license does not replace this data notice.

AnkiDroid's repository also identifies separately licensed components,
including the AnkiDroid API under LGPL-3.0 and parts of the Anki backend under
AGPL-3.0. Those components are not included in the current Dart port. If they
are ported later, their original file or component license and notices must be
retained; this repository does not relicense them under `GPL-3.0-or-later`.

This is an independent project and is not endorsed by or affiliated with the
AnkiDroid or Anki projects. The names are used only to identify the source and
compatibility target.
