# anki-dart

This repository is an in-progress Dart port of AnkiDroid. Its source baseline
is AnkiDroid **2.25.3** (`v2.25.3`); the exact commit and the files compared so
far are recorded in [ANKIDROID_UPSTREAM.md](ANKIDROID_UPSTREAM.md).

## Current port scope

The current port includes selected source-mapped slices: deck-picker behavior,
review-reminder Add/Edit form state,
the headless review-session lifecycle, reviewer count/next-time presentation
models, the collection timebox counter and rounded-minute projection, Previewer
navigation and audio-side selection, flag decision/effect models, ordered
Previewer mark action effects and NoteService mark-tag update effects,
original deck-ID selection for filtered-deck cards,
CardViewer POST request routing and Reviewer POST route selection, Card Browser
active-column and sort preference models, recent-search ordering, JSON
serialization, display state,
saved-history request restoration, Cards/Notes row-ID projection/expansion,
column-selection click-toggle planning, row-tap activation directives, bulk
mark/bury/suspend decisions, and
selected-card flag update effect plans, all-decks filter state,
selected-row export data, marked/suspended preset-search plans, the Card Browser
duplicate-query gate, flag-filter query and effect plan,
note-editor destination payload,
structured search-node planning, the
answer-timer state machine,
reviewer Auto Advance scheduling and toggle effects, leech-feedback
composition, whiteboard and record-voice toggle effects, the headless reviewer
reset-progress, stop-auto-advance, statistics-destination, edited-tag request
projections, operation-executed effect ordering, gesture parser,
parsed-gesture command
routing, reviewer binding codec/map and
default definitions, headless
reviewer keyboard and axis-button dispatch, answer-button command mapping and
AutomaticAnswer action decoding, and reviewer binding preference/default
resolution, Reviewer state-mutation hook decisions, ordered Reviewer question-display effects, and Card Browser
launch-option precedence. Card Browser search-text
transitions, text-edit/sync/reset/history-selection/request-submission effect
sequences and saved-search submission effects, saved-search
outcome-message mapping, search-result message selection, and save-search
prompt decisions,
CardTemplate marker-based string composition and
verbatim card-content QA wrapping, card-template editor unique new-name
generation and exact Markdown projection, browser-appearance onCreate callback ordering and result extraction,
card-template type-answer modifier parsing, cloze-index derivation and
cloze-content extraction, question-side type-answer placeholder removal,
the host-input field/result decision, and answer-side placeholder
substitution using host-computed comparison HTML.

The portable Set Due Date validation and parameter decisions are also included.
Study Options data and state projections preserve buried-count derivation and
Loading/Empty/Congrats/StudyOptions precedence. Its filtered-deck rebuild and
empty actions preserve their diagnostics, selected-deck scheduler operation,
and post-operation collection refresh order; collection reads, flow delivery,
media resolution, undoable scheduling, and UI remain host-side.
Study Options unbury preserves the current-deck lookup inside the undoable
scheduler callback and does not refresh derived state; its host lifecycle and
scheduler operation remain host-side. Study Options refreshData preserves the
open-collection callback boundary for derived-state refresh; collection lookup
and state updates remain host-side. Filtered Deck Options name and limit
validation, second-filter toggling, and build eligibility
are also projected from the pinned source. Collection access, SavedStateHandle,
asynchronous flows, Android UI, query execution, and deck-building mutations
remain host-side.

Media Check unused-file deletion is also projected: a null check result yields
an empty list, the host trashes the supplied list under `DELETING_MEDIA`, and
the deleted count is published only after trash succeeds. Media scanning,
filesystem/backend work, progress execution, and state delivery remain
host-side.

Media Check missing-media tagging preserves the current result's note IDs (or
an empty list when absent) and caller tag for the host bulk-add under
`ADDING_TAGS` and its undoable operation. The host result count is published
only after success; tag storage, progress execution, and state delivery remain
host-side.

Media Check result publication uses `CHECKING_MEDIA` progress and passes the
opaque backend result through only after the host check returns successfully.
The host retains the backend call, progress execution, and result storage.

Login input validation preserves the focus-loss-only empty-field errors, the
nonempty-string button predicate without trimming, and Idle/Success/Error state
variants with opaque error payloads. Authentication, persistence, logging,
localization, lifecycle, and UI remain host-side.

Logged-in logout preserves the host callback order: clear the saved hkey, clear
the username, clear the current sync URI, then force media resync. Callback
failures propagate and stop later callbacks without rolling back earlier host
effects. Preference storage, collection/media access, coroutine scheduling,
lifecycle, and UI remain host-side.

Card Template Editor state preserves the Initializing, Loaded, and Finished
states, source defaults, load/error/finish transitions, and Loaded-only updates.
The host supplies opaque exception data and retains Android lifecycle, StateFlow,
template loading and persistence, rendering, and UI.

The Card Template Editor `EditTab` enum preserves the source values and order
`FRONT`, `BACK`, `STYLING`. Android view IDs, current-tab resolution,
rendering/editing, and host integration remain host-side.

The Card Template Editor `flipQA` transformation preserves the source's greedy
DOTALL answer-separator match, literal `{{FrontSide}}` fallback removal,
U+0020-and-below edge trimming, and question-before-answer setter order. The
host supplies the original strings and setters; template mutation, storage, and
UI remain host-side. See [ANKIDROID_UPSTREAM.md](ANKIDROID_UPSTREAM.md).

Manage Tags remove, rename, and clear-unused actions preserve the selected host
operation, count-bearing event, captured search query, synchronous Loading
transition, and operation → event → reload order. Cancellation is rethrown and
other exceptions are published before the flow stops; collection mutations,
undoable operation, coroutine/job scheduling, StateFlow, events, and UI remain
host-side.

Media Check trash actions preserve `deleteTrash()` / `restoreTrash()` operation
selection and run the chosen host operation inside unlabeled progress and the
collection host. Backend work, coroutine launch, and progress lifecycle remain
host-side.

Empty Cards search preserves the shared Searching state and publishes the exact
host report or thrown object. Cancellation is rethrown through a host-supplied
predicate, and publication errors propagate outside the query catch. Collection
access, query execution, coroutine/job, StateFlow, lifecycle, and UI remain
host-side.

Switch Profiles preserves the empty profile list and add-dialog visibility
state. Confirming a valid name hides the dialog without creating a profile,
matching the pinned source's TODO. Profile loading, validation, logging,
StateFlow, lifecycle, and Android UI remain host-side.

Import add and replace routing preserves the chosen action and original path
string. Flow delivery, coroutine scheduling, importer behavior, and Android UI
remain host-side.

Shared Decks download state preserves the source defaults, retry reset,
Float32 progress calculation, progress-unavailable value, network-wait flag,
and completion/failure transitions. The host retains locale resolution and
one-decimal percentage formatting, DownloadManager/network/file operations,
Android lifecycle, StateFlow, localization, and UI.

- Deck-picker search: token and deck-path matching, with locale-invariant query
  casing and locale-aware deck-name casing, including contextual
  and expanding Unicode mappings, Turkish/Azeri/Lithuanian special cases, and
  partial `:` / `::` searches. `projectDeckPickerFilterUpdate` creates the
  fresh filter value assigned for each input; the host owns StateFlow updates.
- Deck-picker rows and due count: flattening a deck tree into visible rows,
  including ancestor paths, collapsed decks, counts, and selection state; the
  aggregate preserves AnkiDroid's top-level subdeck flag. The source-equivalent
  total due count across top-level decks includes signed 32-bit `Int` overflow
  behavior. An omitted synthetic-root flag is derived from negative depth,
  matching AnkiDroid's level projection.
- Deck-picker position lookup: `findDeckPosition` returns the first visible
  index for a deck or recursively follows the host-resolved parent chain until
  a visible ancestor is found, defaulting to zero when the chain ends. The host
  supplies flattened IDs and resolves parents from the due tree; tree state and
  scrolling remain host-side. No direct pinned source test covers this helper,
  so its Dart cases are source-derived.
- Deck-picker previous-version lookup: `getPreviousDeckPickerVersion` preserves
  the source's Long, Int, and String getter order, typed mismatch catch
  boundaries, exact `"2.0.2"` mapping, and fallback-only key removal. The host
  supplies typed SharedPreferences callbacks and persists the current version;
  Android preference IO stays host-side. Its cases are source-derived.
- Deck-picker sync icon: `planDeckPickerSyncIconFetch` gates auth lookup and
  backend status requests in source order. The lazy
  `projectDeckPickerSyncIconResponse` iterable emits a nonempty endpoint effect
  before status mapping; the host must apply effects as it iterates so endpoint
  persistence still happens before an unrecognized required state throws the
  source TODO as `UnimplementedError`. Caught exceptions map to Normal. The host
  owns auth lookup, backend IO, endpoint preference persistence, exception
  adaptation and logging, coroutine scheduling, and UI. Cases are source-derived;
  see [ANKIDROID_UPSTREAM.md](ANKIDROID_UPSTREAM.md).
- Deck-picker startup: `planDeckPickerStartup` maps the permission gate and startup-job intent; `completeDeckPickerStartup` maps fatal-error and success responses after the host check, preserving source effect order. Permission denial leaves the first-refresh flag unchanged and assigns no startup job; authorized startup sets the flag and assigns its job before failure checking. Failure publishes only FatalError; success configures rendering, launches deck-list loading on IO, then publishes Success without waiting for the load. `planDeckPickerUpdateDeckList` preserves the active-job guard, one-shot first-refresh skip, and ordinary load request; `planDeckPickerScreenResumed` clears that flag. The host supplies Android permissions and startup-failure resolution, schedules IO and coroutine/job/lifecycle work, configures rendering, loads decks, and publishes MutableStateFlow values. The pinned tests directly cover the refresh guard and resume transition, not response/effect sequencing; those Dart cases are source-derived. See [ANKIDROID_UPSTREAM.md](ANKIDROID_UPSTREAM.md).
- Deck-picker selection and context menus: `planDeckPickerSelection` orders collection selection, focused-deck assignment, and deck-list refresh; context-menu plans retain a separate post-join publication payload with the same deck ID, and right-click requests also retain exact coordinates. The host executes selection effects sequentially within the selection job; a selection failure skips focused-deck assignment and refresh. The source then calls `Job.join()`, which waits without rethrowing that failure, so the host publishes the menu request after the job completes even when selection failed. Collection mutation, flows, jobs, and UI stay host-side, and selection preserves the source TODO omission of resetting the Card Browser default deck. Dart cases are source-derived; see [ANKIDROID_UPSTREAM.md](ANKIDROID_UPSTREAM.md).
- Deck-picker expansion toggle: `planDeckPickerExpandToggle` resolves the first depth-first deck match and projects in-memory collapse mutation, persistence with `Scope.REVIEWER`, then list refresh. A missing tree or target still refreshes, while a mutation or persistence failure stops later host effects. The projection leaves the node unchanged; the host applies effects sequentially and owns collection persistence, flow emission, coroutine work, and UI. Dart cases are source-derived; see [ANKIDROID_UPSTREAM.md](ANKIDROID_UPSTREAM.md).
- Deck-picker initial state and counts: `projectDeckPickerInitialState` preserves a null due tree and otherwise requires exactly the default deck as the sole child plus an empty collection. `projectDeckPickerCardsDue` emits a due count only when its tree exists and initial state is exactly false; `projectDeckPickerResizingDividerVisible` preserves the source's nullable comparison, so a null initial-state value with cards shows the divider. The host combines flow emissions and owns StateFlow publication; cases are source-derived. See [ANKIDROID_UPSTREAM.md](ANKIDROID_UPSTREAM.md).
- Deck-picker scheduler-upgrade prompt: `projectDeckPickerSchedulerUpgradePrompt` defaults a missing or wrongly typed Long config value to version 1, prompts only for that legacy version when it has not already been shown, and returns the exact next shown-version value. A null previously shown version compares unequal to 1. The host owns config access, stored-state mutation, and ordered StateFlow/SharedFlow updates; cases are source-derived. See [ANKIDROID_UPSTREAM.md](ANKIDROID_UPSTREAM.md).
- Deck-picker review reminders: `projectDeckPickerScheduleReviewReminders` carries the caller-supplied deck ID unchanged in a host-facing request for deck-specific reminder routing. The host owns coroutine/flow delivery, destination and Intent construction, and reminder handling. Its focused Dart case is source-derived; see [ANKIDROID_UPSTREAM.md](ANKIDROID_UPSTREAM.md).
- Deck-picker export: `projectDeckPickerExportDeck` carries the caller-supplied deck ID unchanged in a host-facing request for publication to the export flow. The host retains `launchCatchingIO`, flow emission, coroutine/IO/error handling, and export execution. The focused Dart case is source-derived; see [ANKIDROID_UPSTREAM.md](ANKIDROID_UPSTREAM.md).
- Deck-picker Manage Note Types: `projectDeckPickerOpenManageNoteTypes` creates a fresh host-facing destination request on every call, matching the source's plain `ManageNoteTypesDestination` class identity. The host retains coroutine/flow delivery, Intent construction, and navigation. Its focused identity case is source-derived; see [ANKIDROID_UPSTREAM.md](ANKIDROID_UPSTREAM.md).
- Manage Note Types: `ManageNoteTypesState` maps case-insensitive filtering, display flags, row selection and multi-select mode, source-order selected rows, editor destinations, destination clearing, and independent transient message/error clears that preserve every other field from the current state. `ManageNoteTypeDeletePlan` maps the single-delete decision, undoable callback order, state outcome, and result forwarding; `ManageNoteTypeDeletionPlan` maps selected-row deletion and error aggregation; `ManageNoteTypeRenamePlan` maps loading-before-scheduling, exact host arguments, latest-row name-only updates, and success/failure result choreography; `ManageNoteTypeRefreshPlan` maps loading-before-query publication and the exact success/failure state updates while retaining an existing error on success. The host supplies note-type rows and retains collection query/use-count lookup, safe-query `Exception` capture, reportable-exception construction, database mutation and undo execution, asynchronous flows, lifecycle, and UI. The focused cases are source-derived; see [ANKIDROID_UPSTREAM.md](ANKIDROID_UPSTREAM.md).
- Edit Deck Description state: `EditDeckDescriptionDialogState` retains restored edits when marked dirty, otherwise initializes from persisted values; it compares both fields only after initialization, distinguishes same-value dirty marking from actual changes, and returns back/close/save decisions with persistence ordered before Saved dismissal. The host supplies persistence values and applies actions; collection access/update, SavedStateHandle, flows/coroutines, lifecycle, and dialog UI remain host-side. Its focused cases are source-derived; see [ANKIDROID_UPSTREAM.md](ANKIDROID_UPSTREAM.md).
- Switch Profiles dialog state: `SwitchProfilesDialogState` starts with no profiles and the add dialog hidden, projects show/dismiss visibility changes, and hides on confirmation without creating a profile because creation remains TODO in the pinned source. ProfileManager/profile IO, ProfileName validation, logging, StateFlow, lifecycle, and Android UI remain host-side. Its focused cases are source-derived; see [ANKIDROID_UPSTREAM.md](ANKIDROID_UPSTREAM.md).
- Import action routing: `projectImportAdd` and `projectImportReplace` produce distinct host-facing actions and carry the supplied path string unchanged. SharedFlow delivery, coroutine/Job scheduling, import backend and importer behavior, and Android UI remain host-side. The focused Dart cases are source-derived; see [ANKIDROID_UPSTREAM.md](ANKIDROID_UPSTREAM.md).
- Shared Decks download state: `SharedDecksDownloadUiState` and the transition functions preserve the source's initial values, retry reset, Float32 progress arithmetic and absolute value, unavailable-progress null, network-wait-only update, and complete/failed fields while retaining all others. `formatDownloadPercent` keeps the source's integer branch and delegates one-decimal output to a host formatter because the source uses process-default locale. DownloadManager, network/file work, localization, Android lifecycle, StateFlow, locale resolution, and UI remain host-side; focused Dart cases are source-derived.
- TTS voice-list and playback state: `projectAvailableVoices` preserves engine-error precedence and exception identity, voice-list failure and Pending behavior, then applies the installed/unavailable and network filters in source order. `planTtsVoicePlayback` keeps the unavailable-voice notification before the engine-ready playback request, including when the engine is not ready; `projectTtsPlaybackError` carries a non-null player error unchanged to the host's main-thread event path. The host supplies voice facts and executes notifications, playback, and error delivery; enumeration, sorting, engine/player setup, refresh, lifecycle, and UI remain host-side. Focused cases are source-derived; see [ANKIDROID_UPSTREAM.md](ANKIDROID_UPSTREAM.md).
- Instant Editor cloze state: `InstantEditorClozeState` preserves field-text word extraction, first cloze-number match and Kotlin Int parsing, full cloze matches, JVM whitespace behavior, source punctuation-merge transitions, ordinal parsing, duplicate/order retention, mode counter transitions, cloze wrapping/removal, clean-cloze replacement over all matches, and Kotlin Int overflow/conversion behavior. Note/collection updates, undoable saves, text selection, editor fields, StateFlow/lifecycle, and Android UI remain host-side; focused cases follow the pinned source, as mapped in [ANKIDROID_UPSTREAM.md](ANKIDROID_UPSTREAM.md).
- Image Occlusion arguments and state: Add/Edit arguments preserve the exact IDs and image path, and mode maps match the source JSON keys. Add mode tracks the selected deck and returns a request to restore the original ID only after a changed selection; Edit mode has no selection. Collection writes, deck-name lookup, coroutine/StateFlow behavior, and Image Occlusion UI remain host-side; see [ANKIDROID_UPSTREAM.md](ANKIDROID_UPSTREAM.md).
- Deck-picker reload-count publication: `planDeckPickerReloadDeckCounts` stages host reads and publications in source order, so a later read failure leaves earlier publications intact. It publishes due-tree and no-cards state before reading studied-today, then stages scheduler config, focused deck, and undo-menu reads around their corresponding updates. It composes the existing scheduler and undo-menu projections and replaces only literal LF characters in studied-today text, preserving CR and other whitespace. The host owns cancellation, IO/jobs, reads, and flow updates; cases are source-derived. See [ANKIDROID_UPSTREAM.md](ANKIDROID_UPSTREAM.md).
- Deck-picker options-menu refresh: `planDeckPickerOptionsMenuRefresh` maps
  collection accessibility, the ten-deck search-icon threshold, undo values,
  the empty-collection predicate, and the intermediate Normal sync icon;
  `completeDeckPickerOptionsMenuRefresh` replaces that icon after the host sync
  fetch. The pinned source constructs the intermediate state before the fetch,
  but assigns only the completed state to StateFlow. The host owns collection
  reads, sync execution/error propagation, StateFlow assignment, and UI.
  `planDeckPickerUndoMenuRefresh` updates only the undo fields when the
  collection is open, preserving a null current state and doing nothing when
  inaccessible. Cases are source-derived; see [ANKIDROID_UPSTREAM.md](ANKIDROID_UPSTREAM.md).
- Deck-picker empty-card deletion: `deckPickerEmptyCardDeletionIds` flattens
  the host report in note order and retains duplicates. With `preserveNotes`,
  it drops the first card ID only for notes marked for deletion; empty and
  single-card lists follow the source's ordinary `drop(1)` behavior. The host
  supplies the report and owns the undoable deletion, orphan-note handling,
  result count, and notification. Cases are source-derived; see
  [ANKIDROID_UPSTREAM.md](ANKIDROID_UPSTREAM.md).
- Deck-picker filtered-deck operations: `planDeckPickerEmptyFilteredDeck`
  preserves selection in one collection block followed by a separate undoable
  empty operation; `planDeckPickerRebuildFilteredDeck` keeps selection and
  rebuild in one collection block. Both defer the scheduler deck ID to the
  host's selected collection ID and publish count changes after success.
  Collection, undo, scheduler, flow, coroutine, and exception behavior remain
  host-side. Cases are source-derived; see [ANKIDROID_UPSTREAM.md](ANKIDROID_UPSTREAM.md).
- Deck-picker unbury operation: `projectDeckPickerUnburyDeck` carries the
  supplied deck ID unchanged for the host's undoable `sched.unburyDeck` call.
  It does not select the deck or publish a deck-list refresh/count-change
  notification. Undo, scheduler, coroutine, error handling, and UI behavior
  remain host-side. Cases are source-derived; see [ANKIDROID_UPSTREAM.md](ANKIDROID_UPSTREAM.md).
- Deck-picker deck deletion: `planDeckPickerDeleteDeck` orders exact singleton
  removal, focus reset to default deck ID `1`, then the deck name and deleted
  card count notification. The host resolves `decks.getLegacy(did)!!.name`
  first, runs removal undoably, and applies later effects only after success.
  `deleteSelectedDeck` remains host-side: it reads the selected ID, delegates
  to `deleteDeck`, and joins that job. Collection access, the source null
  assertion, undo, coroutine, and Flow behavior stay host-side. Cases are
  source-derived; see [ANKIDROID_UPSTREAM.md](ANKIDROID_UPSTREAM.md).
- Deck-picker default-child predicate: `onlyHasDefaultDeck` returns true only
  for exactly one child with the default deck ID (`1`); empty and multi-child
  inputs return false. The host supplies child IDs; due-tree construction and
  collection access remain host-side. Its cases are source-derived; see
  [ANKIDROID_UPSTREAM.md](ANKIDROID_UPSTREAM.md).
- Deck-node lookup and traversal: `find` checks self before descendants and
  returns the first depth-first match, including synthetic nodes. `DeckNode` is
  directly iterable in preorder; its lazy `preorder` iterable and `forEach`
  visit children in order while omitting synthetic nodes and still traversing
  their descendants. `deckIdsForShortcutDisable` maps the first matching
  subtree to decimal ID strings in that iterator order, or returns an empty
  list when the tree or target is missing. The host emits the flow and owns
  tree/backend access and Android shortcut handling. Cases are source-derived;
  backend tree construction and weak-parent behavior remain host-side. See
  [ANKIDROID_UPSTREAM.md](ANKIDROID_UPSTREAM.md).
- Deck-node study readiness and diagnostics: `hasCardsReadyToStudy` is true
  when any review, learning, or new count is positive. `toString` preserves the
  source order of full name, ID, review, learning, and new counts with decimal
  values and comma-space separators. Cases are source-derived; see
  [ANKIDROID_UPSTREAM.md](ANKIDROID_UPSTREAM.md).
- Deck-name paths: `deckNamePath`, `deckNameBasename`,
  `immediateParentDeckNamePath`, and `immediateParentDeckName` preserve
  AnkiDroid's exact `::` split and join behavior, including empty components.
  The host resolves a deck ID to its exact full name and passes both to
  `ShortcutData`, which derives the short label and retains the full long label.
  Flow emission and Android shortcut delivery remain host-side. Cases are
  source-derived; see [ANKIDROID_UPSTREAM.md](ANKIDROID_UPSTREAM.md).
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
- Card Browser column-selection movement: usage-heading rows are not draggable;
  other rows receive vertical movement capability. `planBrowserColumnSelectionMove`
  rejects only target position zero and otherwise returns the source's ordered
  adjacent swaps, including accepted same-position moves with no swaps. The host
  applies the swaps and handles RecyclerView notifications, drag lifecycle, and
  the column-selection dialog. The pinned tests cover drop-refresh timing, not
  this guard or swap sequence, so these Dart assertions are source-derived.
- Card Browser column-selection click toggle: `planBrowserColumnSelectionToggle`
  captures the first Available-heading index, the clicked row index, and the
  source's before-heading side test. Applying its plan removes then inserts at
  that original index without validating; a missing heading remains `-1`, so
  insertion can fail after removal as in the source. The host supplies row
  kinds and owns the click listener, RecyclerView notifications, and dialog.
  Upstream tests cover drag refresh and screenshots, not click toggling; these
  Dart cases are source-derived.
- Card Browser column-selection save: `planBrowserColumnSelectionSave`
  compares the initial and current ordered column lists, emits a pre-update
  dismiss effect only when unchanged, and always supplies the requested mode
  and columns for the host update. Its completion projection dismisses on a
  successful update or shows the source no-columns message and returns false
  otherwise. The source's unchanged-selection fall-through is preserved, so an
  unchanged list can dismiss and still reach the false-result message. The
  pinned tests do not cover this handler; Dart cases are source-derived. The
  host performs the update and delivers dialog/snackbar effects.
- Card Browser column-selection Back: `planBrowserColumnSelectionBack` uses the
  host callback's current enabled state to allow default Back handling or
  request discard confirmation. Confirmation effects disable the discard guard
  before redispatching Back; cancellation emits no effects. The pinned tests
  cover layout only, so Dart assertions are source-derived. The Android
  dispatcher, callback lifecycle, dialog UI and delivery remain host-side.
- Card Browser selected-column replacement: `replaceBrowserSelectedColumn` copies the active columns and replaces every matching key, preserving order and unaffected entries; no match still returns a copy. It follows `CardBrowserViewModel.kt:1484–1497`, called by `ColumnSelectionDialogFragment.kt:102`. Dart cases cover ordinary replacement, repeated-key replacement, order, and no match; the pinned ViewModel tests have no direct assertion. The host calls `updateActiveColumns` and owns mode, guards, persistence, flows, and UI; see [ANKIDROID_UPSTREAM.md](ANKIDROID_UPSTREAM.md).
- Card Browser active-column update decision: `planBrowserActiveColumnUpdate()` rejects empty requested columns first, then rejects ordered structural equality with the current active columns; a changed list is accepted for persistence and requests an active-flow update only for the current mode. The pinned tests exercise a changed-list round trip and use changed columns to build sort-column UI fixtures, but do not assert empty or equal-list rejection. Dart cases are source-derived. The host owns `BrowserColumnCollection.replace`, preference persistence, and the asynchronous active StateFlow update; see [ANKIDROID_UPSTREAM.md](ANKIDROID_UPSTREAM.md).
- Card Browser preference refresh: `planBrowserRefreshColumnsFromPrefs()` first blocks preference loading and active-column updates until initialization completes, then compares the host-loaded mode columns with active columns using ordered structural equality. Changed columns are passed to the host update in stored order. Preference loading, logging, backend work, flows, and coroutine execution remain host-side. No pinned test directly covers `refreshColumnsFromPrefs()`; the Dart cases are source-derived. See [ANKIDROID_UPSTREAM.md](ANKIDROID_UPSTREAM.md).
- Card Browser reinitialization: `planBrowserReinit()` returns no effects until initialization completes, then orders host restoration of active backend columns before the host's asynchronous column refresh. The host retains backend, collection, language/label metadata, coroutine, and StateFlow work. See [ANKIDROID_UPSTREAM.md](ANKIDROID_UPSTREAM.md).
- Card Browser find-and-replace: `planBrowserFindReplace` chooses the Tags or Collection host operation, maps the all-fields sentinel to a null field, and passes selected note IDs and search/replacement/regex/case arguments through unchanged; an unchecked selection passes an empty all-notes list. The host resolves IDs, runs the undoable operation, and returns its count unchanged. The pinned dialog and Card Browser integration tests exercise UI and replacement behavior, but a bounded search found no direct `CardBrowserViewModelTest` operation-mapping assertion; the Dart branch cases are source-derived. Dialog handling, collection access, matching, and result delivery remain host-side; see [ANKIDROID_UPSTREAM.md](ANKIDROID_UPSTREAM.md).
- Card Browser selected-note deletion: `executeBrowserDeleteSelectedNotesPlan` clears a matching pane row before passing the exact host-resolved card-ID list to one undoable removal callback; after success it ends multi-select with the source `Other` cause, refreshes search, and returns the unchanged count. Empty and duplicate IDs are passed through, and a failed removal suppresses later effects. The pinned `CardBrowserViewModelTest` covers deletion/count and selection refresh but has no focused-pane-row assertion; Dart cases are source-derived. Card-ID resolution, pane-row state, collection/undo/count work, multi-select implementation, search refresh, coroutine/effect delivery, and UI remain host-side; see [ANKIDROID_UPSTREAM.md](ANKIDROID_UPSTREAM.md).
- Card Browser card info: `browserCardInfoDestination` returns no destination for an empty selection or a null first resolved card ID, and never tries a later selected row. Otherwise it passes the first card ID unchanged with `CURRENT_CARD_BROWSE`. The pinned `CardBrowserViewModelTest` has no direct assertion for `queryCardInfoDestination`, so Dart cases are source-derived. Selection ordering, Cards/Notes conversion and lookup, destination construction, navigation, flows, UI, and lifecycle remain host-side; see [ANKIDROID_UPSTREAM.md](ANKIDROID_UPSTREAM.md).
- Card Browser column-selection rows: `projectBrowserColumnSelectionRows`
  projects host-supplied column and usage-heading rows into ordered displayed,
  available, and selected column types. It uses the first Available heading,
  strict index comparisons, and the source's `-1` result when that heading is
  absent. Row construction, labels/samples, RecyclerView behavior, saving, and
  state restoration remain host-side; upstream tests cover layout and drag
  callbacks, so Dart assertions are source-derived.
- Card Browser row IDs: `BrowserRowId` associates an ID with Cards or Notes
  mode; `BrowserRowCollection` retains and mutates the supplied list, maps card
  rows to note IDs through a host callback, and expands note rows to cards in
  source order. It snapshots note IDs before asynchronous expansion so later
  row-list mutations do not alter a pending lookup. Per-row selection takes the
  first card, while a note with no cards preserves the source failure. An empty
  Notes-row collection returns an empty result without requiring the host lookup
  callback. Collection lookups remain host-side. Only the
  basic note-to-all-cards behavior has direct upstream integration coverage;
  the dedicated row-collection tests are source-derived. The ViewModel's
  `queryCardIdAtPosition` wrapper returns the first ID from the host query for
  that exact row index and preserves failure when the result is empty.
- Card Browser row position lookup: `browserRowPositionOfId` returns the first
  index matching a host-supplied row ID, or `null` when it is absent. Android
  scrolling, row notifications, and layout-offset calculation remain host-side.
  The generic upstream list helper directly tests first/missing results, but
  AnkiDroid has no direct `getPositionOfId` test; the Dart adapter cases are
  source-derived.
- Card Browser pane-row validity: `ensureBrowserPaneRowValid` clears the pane
  row on phones or when the current row list is empty, falls back to the first
  current row when the pane value is null or stale, and otherwise returns the
  supplied pane value using the host row type's equality. The host invokes it
  after search replacement and owns pane state, UI, and lifecycle. Pinned
  ViewModel tests cover phone behavior and stale-row fallback, but not an empty
  row list or direct retention; Dart tests are source-derived.
- Card Browser post-search pane command: `browserPostSearchPaneCommand` maps a
  host-resolved edit destination to `BrowserPostSearchPaneLoadInPane`, retaining
  the exact destination object, or returns `BrowserPostSearchPaneHidePane` when
  the host supplies null. The host supplies null for a missing pane row or an
  empty/invalid editor destination and owns row lookup, destination resolution,
  command flow delivery, and Android pane UI/lifecycle. Pinned
  `CardBrowserViewModelTest.kt:1595–1625` covers tablet rows and an empty deck;
  it does not assert destination identity. Dart outcome and identity cases are
  source-derived; see [ANKIDROID_UPSTREAM.md](ANKIDROID_UPSTREAM.md).
- Card Browser pane-row refresh positions: `browserPaneRowNotificationPositions`
  projects the previous and new pane IDs to ordered positions, removing duplicate
  IDs and omitting IDs absent from the current rows. Android pane state mutation
  and adapter notifications remain host-side; related upstream tests assert pane
  state but do not directly cover notification targets, so Dart cases are
  source-derived.
- Card Browser selected row ranges: `browserRowRangeBetweenIds` returns the
  inclusive row slice between the first matches for two host-supplied IDs, in
  row order even when endpoints are reversed. Missing IDs preserve the source
  `indexOf`/indexing failure. `planBrowserSelectRowsBetween` merges that range
  into the selected-ID set in insertion order and emits the source mode-change
  and refresh effects only if rows were added. The host applies the set update
  and async delivery. Upstream tests cover range-selection effects but not the
  isolated range projection; Dart cases are source-derived.
- Card Browser long-press and right-click selection: `planBrowserRowLongPress`
  and `planBrowserRowRightClick` choose a range from the last selected ID to
  the pressed row only when multi-select is active and that ID exists; both
  otherwise pass the exact row selection to the toggle operation. Row mutation
  remains host-side. Upstream tests cover long-press selection behavior but not
  the isolated decision or right-click branch, so focused Dart cases are
  source-derived; see [ANKIDROID_UPSTREAM.md](ANKIDROID_UPSTREAM.md).
- Card Browser preview starting index: `browserPreviewStartingIndex` returns
  zero for zero or multiple selected rows and otherwise uses the first matching
  position of the single selected ID, retaining `-1` for stale IDs. The host
  builds preview IDs and launches Android navigation. Upstream tests directly
  cover no-selection and single-selection indices; multi-selection, stale IDs,
  and duplicate browser rows are source-derived.
- Card Browser tag-filter query: `browserFilterTagsQuery` wraps the exact
  host-resolved `SearchRequest.toSearchString()` value in one pair of parentheses
  so an OR tag clause keeps precedence when later combined with AND terms. It
  preserves all existing query syntax and whitespace. `planBrowserTagFilterSearch`
  then models the source order: emit the query, update the current request while
  preserving its structured filters, and request a forced non-user search.
  Request construction/serialization, collection access, flow delivery, request
  state mutation, and search execution remain host-side. Pinned upstream tests
  exercise the OR wrapper; ordered Dart effects and arbitrary-syntax preservation
  are source-derived.
- Card Browser preview payload: `browserPreviewPayload` uses host-supplied
  selected card IDs with index zero for multiple selected rows; otherwise it
  uses host-supplied one-card-per-row IDs and the existing starting-index
  projection. It passes the ID lists through unchanged, including their order,
  and preserves a stale selected row's `-1` index. Collection queries,
  row-to-card mapping, `IdsFile`/cache creation, Android destination creation,
  and activity launch remain host-side. Pinned
  `CardBrowserViewModelTest.kt:990–1041` covers Notes mode, no-selection Cards,
  and single-selected Cards positions; the payload choice and stale-index cases
  are source-derived.
- Card Browser saved selection payload: `browserSavedSelectionPayloadIds`
  preserves a nonempty pending restore; otherwise it snapshots selected rows.
  Empty input means no payload, and emitted IDs retain exact order and
  duplicates. Pinned ViewModel tests cover empty selection and restore timing,
  but do not assert restore precedence or the exact saved ID sequence. The host
  retains the saved-state provider, Bundle/Parcelable, `IdsFile` construction,
  cache-file writes, and restoration lifecycle.
- Card Browser saved selection restore: `planBrowserSelectionRestore` filters
  pending IDs to current rows, merges them after existing selections in source
  order, and emits the `Other` mode cause then refresh only when a new row was
  added. The host clears the pending restore after applying the transition.
- Card Browser preview column order: `projectBrowserPreviewColumns` splits
  host-supplied sample rows into displayed and available lists. Displayed rows
  follow the first matching position in the host-supplied current columns,
  with sample order retained for equal positions; available rows retain sample
  order. It preserves sample identity and leaves both inputs unchanged. Sample
  creation, labels, active-column resolution, preferences, and backend access
  remain host-side. Pinned preview tests cover sample values and an active
  column round trip, but not this list projection; Dart cases are source-derived.
- Card Browser edit-row choice: `browserRowToEdit` returns `null` when there
  are no browser rows; otherwise it chooses the first selected ID in
  multi-select mode without validating membership, or the first browser row in
  normal mode. The host routes the editor and shows the no-row snackbar.
  Upstream tests cover successful editor entry, but not row-choice boundaries;
  Dart cases are source-derived.
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
- Card Browser end-multiselect: `planBrowserEndMultiSelectMode` snapshots the
  selected IDs in insertion order, returns an empty snapshot when none were
  selected, clears the modeled selection, and preserves the exact supplied
  single-select cause object for host publication. The host attaches the
  snapshot to that cause and emits it; fragment scroll anchoring remains
  Android-side. The source has no direct snapshot assertion, so these cases
  are source-derived.
- Card Browser selected-note count: `browserSelectedNoteCount` counts distinct
  note IDs after the host resolves selected rows to notes, matching the source
  `.distinct().size` calculation. No pinned test directly covers this count;
  empty, duplicate, and unique-ID assertions are source-derived. Collection
  lookup and the localized delete-menu plural remain host-side.
- Card Browser selected-row state: `browserSelectedRowCount` and
  `browserHasSelectedAnyRows` project the selected-ID Set's distinct count and
  nonempty check. The host owns selection and uses these values for UI and
  operation guards.
- Card Browser all-decks state: `browserHasSelectedAllDecks` returns true exactly
  when the deck-filter list is empty, independent of query text, other filters,
  or available rows. Pinned ViewModel tests cover the initial/specific and
  AllDecks states; the Dart check for unrelated filters is source-derived.
  Current search flow, result-message delivery, localization, and UI remain
  host-side.
- Deck-picker navigation: `planDeckPickerBrowseCards` orders selecting the
  supplied deck before browsing it; `planDeckPickerAddNote` selects only when
  both the nullable deck ID and `setAsCurrent` permit it, then always preserves
  the original nullable ID in navigation. `planDeckPickerOpenDeckOptions` uses
  either explicit filtered value, including `false`, or asks the host to
  resolve it from the collection when omitted. Collection access, concrete
  Android destinations, and navigation flows remain host-side. These cases are
  source-derived; see [ANKIDROID_UPSTREAM.md](ANKIDROID_UPSTREAM.md).
- Card Browser search result messages: `browserSearchResultMessage` returns no
  message for non-user searches; otherwise it preserves the source order of
  AllDecks, zero selected-deck rows, then a non-empty selected deck. AllDecks
  therefore keeps CardCount with its all-decks action disabled even at zero
  rows, preserving the pinned TODO/quirk. Pinned tests cover each branch except
  AllDecks with zero rows; the Dart test covers that precedence gap. The host
  supplies search values, composes/publishes completed state, and handles
  localization, snackbar actions, UI, navigation, and row-count derivation.
- Card Browser selected-row export data: `planBrowserSelectionExport` returns
  no data for an empty selection; otherwise it maps Cards/Notes mode to the
  matching export kind and copies IDs in the selected-set iteration order.
  Direct ViewModel tests cover empty selection and one row in each mode; order
  and list-copy cases are source-derived. The host still opens the export dialog
  and handles cache files and actual export.
- Card Browser marked/suspended preset searches: `planBrowserPresetSearch`
  stops when the host reports selected rows; otherwise it orders the exact
  `tag:marked` or `is:suspended` query emission, query-only request copy, and
  default refresh-search request. It preserves all existing structured filters.
  Pinned tests cover marked and suspended search results in Cards and Notes,
  but not the selection guard or request/effect details; Dart cases are
  source-derived. The host owns row-selection lookup, flow/request updates,
  collection access, and search execution.
- Card Browser duplicate-query gate: `planBrowserSetQuery` skips request
  assignment and search only when refresh is not forced and the host reports
  equal serialized SearchStrings. Otherwise it copies the exact input query,
  preserves the structured filters, then requests search with the exact
  `forceRefresh` and `fromUserSearch` values (defaulting to `true` and `false`,
  respectively). The host supplies Anki SearchString equality and owns
  request-flow mutation, collection access, search execution, and
  coroutine/cancellation behavior. Pinned ViewModel tests exercise user
  searches but do not directly assert this duplicate-query gate; the Dart cases
  are source-derived.
- Card Browser flag filtering: `browserSearchTermsWithFlag` preserves the
  source's first-match `flag:.` replacement, nonempty-query prepend, and
  incomplete-marker behavior. `planBrowserFlagFilterSearch` composes that
  transformation over the exact host-supplied search terms, then orders filter
  query emission, request update with structured filters preserved, and the
  default refresh search request. The pinned RED flag test verifies the
  resulting search end-to-end but does not assert this query or effect sequence;
  those Dart cases are source-derived. Flag resolution, Flow/request state
  mutation, and search execution remain host-side.
- Card Browser row activation: `planBrowserRowActivation` returns the source-
  ordered directives for normal phone/tablet editor routing and multi-select
  toggles. A selected row tapped in fragmented mode requests a pane reload only
  after the selection toggle; adding a row or deselecting on a phone has no
  editor effect. Upstream ViewModel tests directly cover the major branches.
  The host resolves collection-backed editor destinations, applies selection,
  pane/mode state, and delivers activity or pane commands; Android row widgets,
  flows, and navigation remain outside.
- Card Browser editor card IDs: `browserEditorCardIds` returns no IDs when the
  host cannot resolve the row, all host-resolved sibling IDs in Notes mode, the
  exact selected-card list for Cards-mode multi-select, or the resolved row ID
  alone otherwise. It preserves host list order and identity. Pinned tests
  cover row-tap/editor routing and fragment editor integration, but do not
  assert `getCardIdsForNoteEditor()` results; these branch cases are
  source-derived. Row conversion, collection queries, editor destination
  construction, and UI/lifecycle behavior remain host-side.
- Card Browser note-editor destination: `browserEditNoteDestination` returns
  no destination for an empty host-supplied card-ID list; otherwise it preserves
  that exact list and builds the source `EditSelection` payload with the default
  transition and `inCardBrowserActivity` copied from fragmented mode. The
  pinned `CardBrowserViewModelTest` covers `onTap` command routing but does not
  assert destination fields; the empty, payload, and fragmented cases are
  source-derived. The host retains row/card-ID resolution, mode-specific
  queries, warning/logging, pane-row updates, command/Flow delivery, and Android
  navigation and lifecycle.
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
- Card Browser selected-card deck moves: `planBrowserSelectedCardsMove` emits
  one `setDeck` operation with the exact host-resolved ordered card IDs and
  target deck ID, then passes the operation result through unchanged. The pinned
  Notes-mode test covers two selected note rows resolving to four cards and
  leaves unselected rows unchanged; its Dart cases cover the mapping and empty
  resolved IDs. The host resolves selection, runs the undoable collection
  operation, and reports its changed count in the snackbar.
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
- Card Browser sort-type change: `planBrowserSortTypeUpdate` orders save,
  reverse-direction update, sort-change notification, and search launch. The
  host completes each effect before advancing, so a save failure prevents the
  later publications and search. The notification effect carries the selected
  sort type; the host resolves the current localized label and column type
  while applying it. Pinned `CardBrowserViewModelTest.kt:1908–1985` directly
  covers search launch, integration ordering, and reverse-direction state for
  collection ordering and no ordering; notification construction values are
  not directly asserted.
- Card Browser sort-change notification: `projectBrowserSortChangeNotification`
  maps no ordering directly, or carries the collection sort's supplied label,
  type, and reverse flag. Missing resolved labels use the raw sort key; missing
  types use `unspecified`. Hosts resolve column metadata and deliver localized
  snackbar text. Pinned tests do not directly assert notification values, so
  the projection cases are source-derived.
- Card Browser launch options: `browserLaunchOptionFromUriString` extracts the
  raw URI `search` value, then applies the source order for deep-link search,
  JavaScript search, card ID, or non-empty process text. Empty query values and
  the first exact `search` key are preserved. The raw URI string is required
  because Dart `Uri` canonicalizes escaped query keys. Malformed percent or
  invalid UTF-8 values throw instead of being normalized; Android replaces
  malformed input with U+FFFD, so this edge is outside the equivalence domain.
  Android `Intent`, extras, process-text action, and browser navigation remain
  host-side.
- Card Browser launch initialization: `projectBrowserLaunchState` returns an
  immutable patch with explicit assigned and unchanged fields. It preserves
  exact search text, assigns the JavaScript `allDecks` value even when false,
  and leaves search/deck state unchanged for card-scroll options. Hosts apply
  the patch and retain deck resolution, SavedStateHandle, collection access,
  and search execution. The pinned ViewModel tests directly cover default
  search, system text, and deep-link text; the pure SearchQueryJs/all-decks
  startup assignment and unchanged scroll/null fields are source-derived.
- Card Browser search-box state: `setBrowserSearchQueryExpanded`,
  `updateBrowserSearchQueryText`, and `removeBrowserUnsubmittedInput` emit
  ordered, explicit changes for expansion and unsubmitted text. Collapsing
  clears text before setting expanded false; expanding and text updates leave
  unrelated state unchanged. The host applies the changes to StateFlows and
  owns logging, Android focus, and widgets. Pinned ViewModel tests cover query
  text used by save-search behavior, but do not assert these state transitions;
  the transition assertions are source-derived.
- Card Browser search availability: `browserQueryCanSearch` returns true only
  for a non-null, nonempty query. Whitespace-only text remains searchable; the
  predicate does not trim. The host retains the reactive flow and UI updates.
  No pinned ViewModel test directly asserts this predicate, so the Dart cases
  are source-derived.
- Card Browser save-search prompt decision: `browserSaveSearchPromptQuery`
  returns null for a null or exactly empty temporary query and otherwise
  returns the exact query unchanged, including whitespace-only text. The host
  emits the name-prompt flow and owns Android UI, saving/removing searches, and
  persistence. Pinned ViewModel tests cover empty text and an unchanged `AAA`
  prompt query, but not null or whitespace-only values; the complete Dart cases
  are source-derived.
- Card Browser initial selected deck: `planBrowserInitialDeck` reports when the
  host must consume the launch-intent saved-state flag and chooses a valid
  resolved intent deck, the all-decks sentinel, a host-validated persisted
  deck, or the current host-selected deck in source order. Intent extraction,
  deck lookup/name resolution, `SavedStateHandle`, collection access, and
  `setSelectedDeck` persistence remain host-side. The pinned direct tests
  assert intent deck ID selection/persistence, persisted-deck fallback for a
  missing or unknown intent ID, and user selection persistence across process
  death; they do not assert consumed-flag transition, deck names, all-decks
  sentinel precedence, or fallback to the host-selected deck. The Dart cases
  for those unasserted branches are source-derived.
- Card Browser selected-deck updates: `planBrowserSelectedDeckUpdate` selects
  the source `lastDeckId` value, prepares an empty AllDecks or singleton
  host-resolved deck filter, copies only that filter into the current request,
  then requests search with `forceRefresh = false`. The host persists the ID
  before applying search effects and owns request-flow mutation, collection
  access, and search execution. Pinned tests directly assert selected-deck
  persistence and indirectly exercise search outcomes, but do not assert the
  complete plan order, preserved request fields, or false refresh argument;
  those Dart assertions are source-derived.
- Card Browser post-search initial scroll: `planBrowserPostSearchScroll`
  returns no effects without a pending target; otherwise it orders clearing the
  target before lookup. After the host completes that lookup,
  `completeBrowserPostSearchScrollPlan` adds a zero-offset request only when the
  card exists and has been mapped to a row ID. Search synchronization,
  collection lookup and Cards/Notes mapping, flow delivery, and RecyclerView
  scrolling stay host-side. Pinned tests cover valid, missing, cleared, and
  Notes-mode targets; absent-target, clear-before-missing, host-row-ID
  passthrough, offset, and plan order cases are source-derived.
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
- Previewer audio selection: `previewerAudioSide` selects both card sides
  for autoplay in back-side-only mode, otherwise the currently shown question
  or answer side. The host loads media tags and performs playback; see
  [ANKIDROID_UPSTREAM.md](ANKIDROID_UPSTREAM.md).
- Previewer navigation: `PreviewerNavigationModel` applies the source button
  enablement formulas, next/previous transitions, back-side-only mode, and
  one-based slider selection. It returns a show-side or load-card intent for the
  host to carry out; card lookup, rendering, and media playback remain outside.
- Template Previewer tabs: `previewerToggleShowAnswerEffects` orders the
  selected-side display before its audio load; the ordinal helpers preserve
  cloze tab indexing and source lookup behavior while leaving card updates and
  tab widgets to the host. See [ANKIDROID_UPSTREAM.md](ANKIDROID_UPSTREAM.md).
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
  escape or normalize input. Android-side filtering, media-reference resolution,
  bold rewriting, rendering, and orchestration remain with the host.
- Resolved card media markup: `cardAudioPlayButtonMarkup` returns AnkiDroid's
  exact SVG play-button fragment for host-resolved audio/TTS references and
  returns an empty string when the audio-button option is off.
  `cardVideoTagMarkup` returns the exact video element using a host-supplied
  URI and HTML-escaped filename. The host still parses media references,
  classifies tags, resolves paths and filenames, expands the card content, and
  handles Android playback and WebView integration.
- Previewer flags: `PreviewerFlag` preserves the source codes 0–7, and the
  set/toggle projections return a one-card collection-write intent followed by
  publication of the same flag only if the host write succeeds. Current-card
  lookup, the undoable collection operation, asynchronous failure handling and
  StateFlow publication remain with the host. This enum is separate from the
  Card Browser backend search flag values.
- Previewer mark toggle: `previewerToggleMarkEffects` orders the host-resolved
  current-note mark toggle before a post-toggle marked-state read and publication.
  The host stops the sequence when an operation fails; note lookup, `marked` tag
  mutation, undoable persistence, error handling, and StateFlow delivery remain
  host-side.
- Reviewer mark toggle: `planReviewerMarkToggle` exposes the host-resolved note
  toggle, a marked-state read only after toggle success, and publication only
  after read success. The pinned Reviewer tests do not assert this effect order;
  source-derived cases cover both failure gates. Card/note lookup, NoteService
  calls, `marked` tag mutation, persistence, action dispatch, and StateFlow
  delivery remain host-side.
- Reviewer mark/flag icon presentation: `reviewerMarkIconVisibilityUpdate`
  preserves toolbar suppression and otherwise follows the marked Boolean;
  `reviewerFlagIconPresentation` preserves toolbar suppression, hides for NONE,
  or passes through the selected flag with a show update. The pinned Reviewer
  tests do not assert these icon collector decisions, so the Dart cases are
  source-derived. Flow collection, preference reads, drawable lookup and
  Android view updates remain host-side.
- NoteService mark update: `planNoteServiceToggleMark` removes the literal
  `marked` tag when the supplied state is true or adds it when false, then
  requests undoable note update. The host reads state, mutates the note, and
  performs persistence.
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
- Template Previewer type-answer prompt: `filterTemplatePreviewerTypeAnswerQuestion`
  replaces the first matching question marker with the exact source read-only
  example input HTML, then replaces every later match with host-supplied warning
  HTML. The host retains Previewer state, localization, and rendering.
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
- Type-answer input eligibility: `typeAnswerValidForEditText` returns true
  exactly when input-tag mode is disabled and the correct answer is non-null;
  an empty string still counts as non-null. `typeAnswerAutoFocusEditText` adds
  the source `autoFocus` condition. The host supplies these values and owns
  Android field visibility, focus, and input lifecycle.
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
- Reviewer stop-auto-advance request: `reviewerStopAutoAdvanceDirective`
  returns a payload-free request for the host to cancel its existing question
  and answer jobs. Logging, lifecycle callers, cancellation, and timer behavior
  remain host-side. The pinned source has no direct Reviewer test for this
  request; see the source mapping in `ANKIDROID_UPSTREAM.md`.
- Reviewer Auto Advance toggle: `planReviewerAutoAdvanceToggle` orders the
  enabled-state update, state publication, localized feedback, and shown-side
  scheduling request. It skips scheduling only when the host reports both
  wait-for-audio and active playback; otherwise it retains the source request
  even when disabled. Settings, localization, media state, timer operations,
  and StateFlow delivery remain host-side.
- Reviewer leech feedback: `reviewerLeechFeedbackMessage` returns the base
  localized string unchanged unless the host reports suspension. For suspended
  cards, it appends one literal ASCII space and the supplied suspended message
  without normalization. Detection, card reload, queue lookup, localization,
  logging, and feedback delivery remain host-side.
- Reviewer delete-note effects: `executeReviewerDeleteNotePlan` sends the
  host-resolved current card ID as a singleton list to the undoable removal
  callback, passes its returned count into host localization, delivers that
  message, then requests a current-card reload. A failed removal stops before
  localization, feedback, and reload. Current-card lookup, collection access
  and deletion, result extraction, resource localization, feedback Flow, and
  reload remain host-side. The pinned Reviewer tests have no direct delete-note
  order assertion; source-derived cases are in
  `test/reviewer_delete_note_plan_test.dart`. Card Browser bulk deletion is a
  separate operation.
- Reviewer flag toggle effects: `planReviewerToggleFlag` composes the existing
  flag target decision with the Reviewer singleton write and publish-on-success
  plan. A matching requested/current flag selects NONE; a different request is
  preserved. The pinned Reviewer tests do not directly cover this action, so
  source-derived cases cover target selection, exact card targeting, success
  ordering, and write-failure suppression. Dispatch, flag-state reads, card
  lookup, undoable collection mutation, exceptions, StateFlow delivery, and
  lifecycle remain host-side; see `ANKIDROID_UPSTREAM.md`.
- Reviewer flag command mapping: `reviewerFlagCommandOperation` maps each
  existing `ViewerCommand.TOGGLE_FLAG_*` to a typed Toggle operation carrying
  its corresponding source `Flag`, and `UNSET_FLAG` to a typed Set operation
  carrying `Flag.NONE`. The pinned `ReviewerViewModelTest.kt` has no direct
  assertion for this command-to-outcome mapping, so focused cases are
  source-derived. The host retains action dispatch, flag-flow reads,
  current-card lookup, undoable collection writes, and publication; menu-only
  `FLAG_*` actions are outside `ViewerCommand`. See `ANKIDROID_UPSTREAM.md`.
- Reviewer undo/redo feedback: `reviewerUndoRedoFeedbackMessage` selects the
  host-localized no-operation string for an empty operation, or invokes the
  matching undo/redo message callback with a nonempty operation unchanged.
  Undo availability and execution, protobuf extraction, localization,
  Reviewer action dispatch, and feedback Flow delivery remain host-side.
- Reviewer operation-executed effects: `planReviewerOpExecutedEffects` always
  requests undo/redo labels first, returns after that request when the host's
  source `handler == this` comparison is true, then selects study-queue,
  note-text, or card effects in source precedence. Note-text requests reload
  the card, load AV tags, update the mark
  icon, and render the host-selected side; card requests reload before updating
  the flag icon. The host owns change/handler reads and executes callbacks in
  order, stopping naturally on failure; see `ANKIDROID_UPSTREAM.md`.
- Reviewer show-answer effects: `planReviewerShowAnswerEffects` preserves the
  mutation wait, typed-answer result publication/default and 1,000 ms result
  timeout, next-time update, answer display, answer-side media, audio-gated
  Auto Advance callback, and timer hidden-state read in source order. Hidden
  timers skip current-deck/config reads; visible timers request them before the
  host applies `stopTimerOnAnswer`. Deferred/coroutine execution, mutable
  Reviewer state, scheduler/deck/media/timer access, Flow/lifecycle, and UI
  remain host-side; see `ANKIDROID_UPSTREAM.md`.
- Reviewer state-mutation hook: `reviewerStateMutationHookDecision()` requests
  completion only for empty JavaScript with an incomplete host signal; an already
  completed signal produces no action. Nonempty JavaScript returns the exact
  raw triple-quoted source template, including its leading newline, indentation,
  and trailing newline/spaces, with raw state-key/JavaScript interpolation; it
  leaves signal completion to the later host callback. The pinned source test
  context at `ReviewerViewModelTest.kt:81–112` covers restored custom-scheduler
  waiting and retained-ViewModel non-rerun behavior; it does not directly assert
  the empty-JavaScript branch or exact script formatting, which are covered by
  source-derived cases in `test/reviewer_state_mutation_hook_test.dart`. Awaiting
  the JavaScript, SharedFlow emission/delivery, callback failure propagation,
  mutation-signal completion, scheduler execution, WebView and lifecycle remain
  host-side. See [ANKIDROID_UPSTREAM.md](ANKIDROID_UPSTREAM.md).
- Reviewer question display: `planReviewerShowQuestionEffects()` requests a new
  mutation signal only when the current one is complete, then preserves the
  source order for showing the question, running the state-mutation hook,
  updating mark and flag icons, and conditionally notifying Auto Advance.
  Waiting for audio omits that notification so the host's existing media-group
  completion callback remains responsible. The host retains signal lifecycle,
  rendering, hook execution, collection reads and Flow publication, coroutine
  and error boundaries, media callbacks, and UI; see `ANKIDROID_UPSTREAM.md`.
- Reviewer media replay side: `reviewerReplayMediaSide` maps the host-supplied
  `showingAnswer` value to `back` when true and `front` when false, matching the
  pinned `replayMedia()` side choice. The pinned Reviewer tests have no direct
  PLAY_MEDIA action assertion, so both cases are source-derived in
  `test/reviewer_replay_media_side_test.dart`. State access, action dispatch,
  `cardMediaPlayer.replayAll`, media playback, and lifecycle remain host-side.
- Reviewer current-card info: `reviewerCurrentCardInfoDestination` pairs the
  host-resolved current card ID unchanged with the source
  `EntryPoint.CURRENT_CARD_STUDY`. The pinned Reviewer tests have no direct
  assertion for this action, so the ID pass-through and entry-point cases are
  source-derived in `test/reviewer_current_card_info_destination_test.dart`.
  Current-card lookup, concrete `CardInfoDestination` construction, navigation
  Flow, and Android/lifecycle handling remain host-side.
- Reviewer edit-note destination: `reviewerEditNoteFromPreviewerDirective`
  carries the host-resolved current card ID unchanged in a typed directive
  corresponding to `NoteEditorDestination.EditNoteFromPreviewer(cardId)`.
  The pinned Reviewer tests have no direct EDIT destination assertion, so
  pass-through cases are source-derived in
  `test/reviewer_edit_note_destination_test.dart`. Current-card lookup, logging,
  concrete Android destination construction, navigation Flow, and lifecycle
  handling remain host-side.
- Reviewer add-note destination: `reviewerAddNoteFromReviewerDirective()`
  returns a payload-free typed directive corresponding to
  `NoteEditorDestination.AddNoteFromReviewer()`. The pinned Reviewer tests have
  no direct ADD_NOTE destination assertion, so the no-payload mapping is
  source-derived in `test/reviewer_add_note_destination_test.dart`. Logging,
  concrete Android destination construction, navigation Flow, and lifecycle
  handling remain host-side.
- Reviewer reset progress: `reviewerResetProgressDirective()` returns a
  payload-free typed directive for one `resetProgressFlow` emission. The pinned
  Reviewer tests have no direct RESET_PROGRESS assertion, so this mapping is
  source-derived in `test/reviewer_reset_progress_directive_test.dart`.
  Confirmation UI, SharedFlow delivery, reset implementation, and lifecycle
  handling remain host-side.
- Reviewer edit-tags request: `reviewerEditTagsDirective()` carries the host-resolved
  note ID unchanged and exposes it as the singleton `noteIds` list passed to the
  tag-dialog factory. The pinned flow is `NoteId` at
  `ReviewerViewModel.kt:102`; `editNoteTags()` awaits the current card and emits
  its note ID at `:660–663`, and `ViewerAction.TAG` dispatches it at `:722`.
  `ReviewerFragment.kt:626–628` passes `listOf(noteId)` to the dialog factory.
  No direct pinned `ReviewerViewModelTest` assertion covers this flow payload;
  the Dart pass-through and singleton cases are source-derived. Current-card and
  collection reads, action dispatch, SharedFlow delivery, Android dialog
  creation, and lifecycle remain host-side. This opening request is separate
  from the F131 `reviewerEditedTagsDirective()` result decision below.
- Reviewer edited tags: `reviewerEditedTagsDirective()` returns no request for
  structurally equal ordered tag lists; otherwise it carries the selected tags
  joined with one literal ASCII space, preserving order, duplicates, empty
  elements, and whitespace. The pinned `onEditedTags` implementation is at
  `ReviewerViewModel.kt:665–679`, called from `ReviewerFragment.kt:670`; no
  direct pinned `ReviewerViewModelTest` assertion was found, so focused Dart
  cases are source-derived. Current-card/note/collection lookup,
  `note.setTagsFromStr`, undoable `updateNote`, logging, and coroutine delivery
  remain host-side. Card Browser and Previewer mark-tag paths are separate.
- Reviewer answer-button next-time publication:
  `projectReviewerAnswerButtonsNextTimeUpdate()` returns no update when the
  host-resolved setting hides times or the host has no computed value; when
  visible, it carries the existing `AnswerButtonsNextTime` unchanged. The
  source gate is `ReviewerViewModel.kt:651–658`, with a nullable flow at `:138`
  and callers at `:148–149` and `:224`. No direct pinned
  `ReviewerViewModelTest` assertion covers the gate/publication decision;
  `ReviewerTest.kt:383–390` checks a button-label update end to end, so these
  Dart cases are source-derived. Settings and queue reads, scheduler
  calculation, coroutine and StateFlow delivery, and answer-button sizing
  remain host-side.
- Reviewer previous-card info: `reviewerPreviousCardInfoDirective` selects
  host-localized no-card feedback for a null saved previous-card ID and carries
  every non-null ID unchanged into a navigation directive. SavedStateHandle,
  current/saved state access, `CardInfoDestination` construction, navigation
  Flow, localization, and feedback Flow delivery remain host-side. The pinned
  Reviewer tests have no direct assertion for this action; null/non-null cases,
  including zero pass-through, are source-derived in
  `test/reviewer_previous_card_info_directive_test.dart`.
- Reviewer browse destination: `reviewerBrowseToCardDirective` carries the
  host-resolved deck and card IDs unchanged into a browse-to-card directive,
  corresponding to `BrowserDestination.ScrollToCard`. The pinned Reviewer
  tests have no direct BROWSE assertion, so exact-ID cases are source-derived
  in `test/reviewer_browse_destination_test.dart`. Collection/current-card
  reads, Android destination construction, navigation Flow, and lifecycle
  remain host-side.
- Reviewer statistics destination: `reviewerStatisticsDestination()` selects
  the payload-free statistics destination for `ViewerAction.STATISTICS`. The
  pinned Reviewer tests have no direct assertion for this branch; the mapping
  case is source-derived. Flow delivery, Android intent/activity navigation,
  and statistics UI/collection access remain host-side. `STATISTICS` is not a
  `ViewerCommand` and adds no binding. See `ANKIDROID_UPSTREAM.md`.
- Reviewer whiteboard toggle: `planReviewerWhiteboardToggle` inverts the
  host-supplied state, publishes the new value, then requests assigning that
  same value to the repository preference. StateFlow mutation, repository
  access/write, action dispatch, and UI remain host-side.
- Reviewer record-voice toggle: `planReviewerRecordVoiceToggle` inverts the
  host-supplied state, publishes the new value, then requests assigning that
  same value to the repository preference. StateFlow mutation, repository
  access/write, action dispatch, recorder lifecycle, and UI remain host-side.
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
`browserSaveSearchPromptQuery` returns no prompt query only for null or exactly
empty temporary input; every other string is passed through unchanged, including
whitespace-only text. The host emits the prompt and owns Android UI, saved-search
mutation, and persistence.
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
serialization and equality, search execution, search-string conversion,
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
the column-selection dialog and RecyclerView click/drag lifecycle/notifications,
and active backend column updates (movement capability, adjacent-swap planning,
and click-toggle planning are modeled); Card Browser sort UI, Android
preference/synced-config IO, and actual backend row sorting,
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
and note editing, Android card-template asset loading,
card template rendering and media-reference resolution/playback (resolved
audio-button and video-tag markup fragments are modeled), card/note-dependent
TypeAnswer field and note-value lookup
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
lifecycle presentation, leech handling, undo/redo availability and execution, JavaScript custom-
state and gesture bridges, WebView state collection, Android timeout lookup,
sync, actual import/export, and other app features remain to be ported. The
selected-row export-data projection is modeled, but its dialog, file handling,
and export implementation remain host-side. The portable Export Ready ViewModel
slice models the initially empty request, unchanged immutable parameters, and
clearing to null. It preserves the exact export path and `asText` default;
SavedStateHandle/StateFlow/Parcelable, Android lifecycle and logging,
dialog/navigation, file access, and export execution remain host-side.
The portable Multimedia ViewModel state slice preserves nullable opaque URI and
path values, the saved values used by restore, and signed media lengths.
SharedFlow action emission/coroutines, String-to-File conversion, Android
media/file/URI operations, lifecycle, and UI remain host-side.
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

Card Browser appearance state transfer uses `saveBrowserAppearanceInstanceState` to read and write question format before answer format, then call superclass saving. `initializeBrowserAppearanceUiFromBundle` restores question then answer values, calls `hasChanges` once, publishes the discard-enabled state, enables the toolbar, then sets the localized title. Nullable saved values pass through unchanged, and callback failures stop later work. The host owns Bundle and EditText access, localization, toolbar and Activity lifecycle, and superclass invocation. Change detection and menu routing preserve their source callback order; only Home calls `hasChanges`, and unknown menu actions return the superclass result unchanged. The discard dialog finishes only after confirmation, and the restore-default dialog restores and closes only after confirmation; cancellation or dismissal performs no callback. Dialog construction and user-choice delivery remain host-side. It assumes changes on `Exception` while allowing Dart `Error` to propagate. Focused cases are source-derived; see [ANKIDROID_UPSTREAM.md](ANKIDROID_UPSTREAM.md).

## Use and verify

This package currently contains library code, not a runnable app. It supports
Dart `>=3.11.0 <4.0.0`:

```sh
dart pub get
dart test
```

The Card Browser reposition plan projects source-ordered eligible and skipped
card IDs from host-resolved card type and queue states. Collection access,
queue-position calculation, and scheduler operations remain host-side.
The selected-rows scheduler request carries the host-resolved card IDs in order
and the exact position, step, shuffle, and shift arguments to `sched.sortCards`;
the host scheduler result count passes through unchanged. Selection resolution,
undo, coroutine, scheduler execution, and UI remain host-side.
Its presentation projection maps host-supplied result values to dialog or
snackbar directives; resource lookup and Android UI construction/delivery stay
host-side.
The queue-bounds projection orders two host-supplied values and preserves the
source behavior that either missing value clears both bounds.
The due-extrema projection preserves the source lower-only zero clamp and passes
max due unchanged before bound ordering; database reads remain host-side.
The summary projection joins host-localized queue lines with one newline and
returns null when either queue bound is absent; localization remains host-side.
The Card Browser note-type response plan checks selected IDs against a
host-resolved membership set and preserves first-occurrence order for the
change result. Type lookup, flows, UI, and note mutation remain host-side.
The response presentation plan maps mixed-note-type results to a host-resolved
snackbar resource and compatible results to a dialog carrying the same IDs;
logging and UI delivery remain host-side.
The ChangeNoteType conversion-direction projection maps the host's regular and
cloze status flags across all four source combinations; note-type lookup,
templates, conversion and sync remain host-side.
The default field-map projection uses host-resolved ordered names and ordinals,
preserving the source's exact-name first match, duplicate-key and fallback
behavior. Collection access, state flow, user mapping changes, UI, note
conversion, template mapping and persistence remain host-side.
The discarded-fields projection consumes the host's current field map and
ordered input names, preserving source-index filtering, duplicate names, null
and out-of-range values. StateFlow, field lookup, localization and dialog UI
remain host-side.
The default template map rebuild maps matching ordinals and returns null for
extra outputs; an empty output count produces an empty map. Template lookup,
StateFlow, UI, persistence and conversion remain host-side.
The template-mapping update projection consumes the host's enabled state,
current map, output ordinal and nullable selected ordinal; it preserves the
source collision-clearing and missing-key behavior. Flow delivery, type lookup,
spinner/UI, persistence and note conversion remain host-side.
The field-mapping update projection copies the host's current map and assigns
the supplied nullable input ordinal at the output key, preserving duplicate
and unvalidated ordinals. StateFlow, spinner/UI, logging and note conversion
remain host-side.
The ChangeNoteType has-changes projection compares host-supplied type IDs and
default/current maps. It uses structural, order-independent map equality and
distinguishes absent keys from null-valued keys. Flow composition and Save-button
state delivery remain host-side.
The discarded-template projection filters host-supplied ordered names by their
source list indices. It preserves duplicate names and order; null and
out-of-range mapping values do not remove entries. Flow and warning UI delivery
remain host-side.
Template changes are eligible only for the host-resolved regular-to-regular
conversion. The settled Boolean is projected separately from the host-managed
flow initial value and delivery.
The ChangeNoteType tab-position projection maps 0 to Fields and 1 to Templates;
unknown positions throw. ViewPager input and tab-state delivery remain host-side.
The `SelectedIndex` model preserves the singleton Nothing choice and value-equal
index choices, converting them to nullable ordinals without range checks.
Spinner selection, map updates, StateFlow and UI lifecycle remain host-side.

## License and attribution

The adapted AnkiDroid code is derived from AnkiDroid and is distributed under
**GNU GPL version 3 or, at your option, any later version** (`GPL-3.0-or-later`).
The source repository's root `COPYING` is the GNU GPL version 3 text; the
matching SPDX license text is included at
[`LICENSES/GPL-3.0-or-later.txt`](LICENSES/GPL-3.0-or-later.txt). Copyright and
SPDX notices remain in each adapted Dart source file. See [NOTICE.md](NOTICE.md)
for source-file attribution.

The locale-casing property ranges, lowercase mappings, and BMP decimal-digit
block starts in `lib/src/unicode_15_case_data.dart`, along with simple BMP case
mappings in `lib/src/unicode_15_simple_case_mappings.dart`, are derived from
Unicode 15.0.0 UCD data (`UnicodeData.txt`, `PropList.txt`,
`DerivedCoreProperties.txt`, and `SpecialCasing.txt`), Copyright © 2022 Unicode,
Inc., and are distributed
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

## Card Template Editor new names

`newCardName()` in `lib/src/card_template_editor_new_card_name.dart` follows
`CardTemplateEditor.kt:1629–1641` at AnkiDroid v2.25.3 commit
`d9bf072f814a0c37d30a694192593b31ff2df875`. It starts at the host-supplied
template count plus one, localizes each candidate once, and returns the first
name absent from the ordered existing names using exact, case-sensitive
equality. It preserves Kotlin signed 32-bit overflow and stops scanning at the
first match; callback and iteration failures propagate in source order. The host
retains `CardTemplates`, its length and names, and localization. Focused tests in
`test/card_template_editor_new_card_name_test.dart` are source-derived; no
direct pinned test for `newCardName` was found.

## Card Template Editor EditTab

`CardTemplateEditorEditTab` in `lib/src/card_template_editor_edit_tab.dart`
maps `EditTab` at `CardTemplateEditor.kt:1680–1684` from AnkiDroid v2.25.3
commit `d9bf072f814a0c37d30a694192593b31ff2df875`. It preserves exactly three
distinct values in source order: `FRONT`, `BACK`, `STYLING`; Dart's enum index
therefore retains the source ordinal. Android view IDs, current-tab resolution,
rendering/editing, and host integration remain host-side. Focused cases in
`test/card_template_editor_edit_tab_test.dart` are source-derived; the pinned
source has no direct enum-focused test. See [ANKIDROID_UPSTREAM.md](ANKIDROID_UPSTREAM.md).

## Card Template Editor note type change check

`cardTemplateNoteTypeHasChanged()` in
`lib/src/card_template_editor_note_type_changed.dart` preserves
`CardTemplateEditor.kt:406–414` from AnkiDroid v2.25.3 commit
`d9bf072f814a0c37d30a694192593b31ff2df875`. Without a temporary note type it
returns false before invoking the stored-type lookup, preserving the early
lifecycle guard against opening the collection. Otherwise it invokes the host
lookup once: an absent stored type means changed, and a present type means the
negation of the host-projected JSON content-equality result. Callback errors
propagate unchanged. Collection access, generated note-type models, and
`JSONObject.contentEquals` remain host-side; JSON is not serialized or
normalized. Focused cases in
`test/card_template_editor_note_type_changed_test.dart` derive from the pinned
`CardTemplateEditorTest.kt` behavior and source logic. See
[ANKIDROID_UPSTREAM.md](ANKIDROID_UPSTREAM.md).


## Card Template Editor Markdown

`cardTemplateToMarkdown()` in `lib/src/card_template_editor_markdown.dart`
tracks the nested `CardTemplate.toMarkdown(context)` at
`CardTemplateEditor.kt:1644–1661` from AnkiDroid v2.25.3 commit
`d9bf072f814a0c37d30a694192593b31ff2df875`. It preserves the exact section
order and LF fence layout, interpolating the supplied front, back, style, and
three localized headings without escaping, trimming, or normalizing them. The
CSS fence has no final LF. Android `Context`, generated localization, and
Markdown rendering remain host-side; see
[ANKIDROID_UPSTREAM.md](ANKIDROID_UPSTREAM.md). Focused exact-output tests are
source-derived because the pinned source has no direct test for this formatter.
