# anki-dart

This repository is an in-progress Dart port of AnkiDroid. Its source baseline
is AnkiDroid **2.25.3** (`v2.25.3`); the exact commit and the files compared so
far are recorded in [ANKIDROID_UPSTREAM.md](ANKIDROID_UPSTREAM.md).

## Current port scope

The current port includes twelve source-mapped slices: deck-picker behavior, the
headless review-session lifecycle, reviewer count/next-time presentation
models, the collection timebox counter and rounded-minute projection, Previewer
navigation, Card Browser active-column and sort preference models, the
answer-timer state machine, reviewer Auto Advance, the headless reviewer
gesture parser, parsed-gesture command routing, and the reviewer binding
codec/map.

- Deck-picker search: token and deck-path matching, with locale-invariant query
  casing and locale-aware deck-name casing, including contextual
  and expanding Unicode mappings, Turkish/Azeri/Lithuanian special cases, and
  partial `:` / `::` searches;
- Deck-picker rows and due count: flattening a deck tree into visible rows,
  including ancestor paths, collapsed decks, counts, and selection state, plus
  the source-equivalent total due count across top-level decks.
- Card Browser columns: `BrowserColumnCollection` recognizes the source column
  keys, loads an ordered `|`-separated value with load-time de-duplication and
  fallback to caller-supplied defaults, and returns serialized update results
  after removing null entries. Successful updates preserve duplicate entries
  until the next load, matching the source method behavior. The host supplies
  mode-specific default keys and persists the returned value; SharedPreferences
  and backend/UI integration stay outside.
- Card Browser sort choice: `resolveBrowserSortType` reads caller-supplied
  mode-specific config values, checks the key against host-supplied backend
  columns, and returns the source sort type. It defaults missing or
  wrong-typed values to `noteFld` and forward order, treats an unknown column as no ordering, and
  creates ordered save plans without touching Android or collection storage.
  The shared no-sorting flag retains the source's cross-mode behavior.
- Review session: a headless flow that loads the scheduler's current card, shows
  its question or answer, forwards an Again/Hard/Good/Easy rating, then loads
  the next queue item. It waits for the current card's state-mutation hook
  before revealing or grading it, and pauses for a scheduler timebox event
  before showing the queued card. The previously displayed side remains visible
  during the timebox and while a queue read loads or retries. A failed queue
  read can be retried without sending the completed card's rating again.
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
  by command, without loading preferences or adding default bindings. It keeps
  every key and gesture registration in action order and per-command list
  order, ignores side when matching while retaining the original side in each
  result, skips unknown bindings, and lists axis registrations separately.
  This differs from `GestureCommandRouter`, whose source-mapped behavior lets
  the later command overwrite a duplicate gesture. `ReviewerBindingMap` only
  returns registrations; the existing router API and optional executor remain
  unchanged.

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
value. The adapter also supplies the mode defaults, so the port does not copy
`BrowserConfig.kt`'s AGPL-incorporated constant definitions.
`resolveBrowserSortType` and `buildBrowserSortSavePlan` consume the shared
no-sorting flag and the active mode's config keys/values from the host. They
also consume the backend's available column keys. The save plan writes the
mode-specific column and reverse keys in source order before clearing the
global no-sorting flag; actual preference/config writes and backend sorting
remain host responsibilities. This keeps `BrowserConfig.kt` key lookup and
its AGPL-incorporated constants outside the Dart port.
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
Card Browser SharedPreferences and mode lookup, AGPL-incorporated column defaults,
backend column registry and rows, column-selection drag/drop and active backend
updates, Card Browser sort UI, Android preference/synced-config IO, and actual
backend row sorting,
Previewer SavedStateHandle/card-ID plumbing, collection-backed card loading,
WebView rendering and media, previewer flags/marks/note editing, answer-timer widget/tick rendering, Auto Advance settings controls and
Android preference lookup, Android `KeyEvent` handling and `possibleKeyBindings`,
binding display strings, MotionEvent axis interpretation, `BindingProcessor`
callbacks, command execution, touch input and reviewer command handlers,
study-count and answer-button widgets/layout, next-time visibility preference
wiring, template rendering and media, localized timebox messages, dialog and
lifecycle presentation, leech handling, reviewer undo/redo, JavaScript custom-
state and gesture bridges, WebView state collection, Android timeout lookup,
sync, import/export, and other app features remain to be ported.
The source project has thousands of files, so this repository does not claim
full feature parity.

The port preserves the source behavior for the covered slices, including search
and collapse quirks, ordered Card Browser columns and load-time de-duplication,
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
