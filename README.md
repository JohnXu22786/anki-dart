# anki-dart

This repository is an in-progress Dart port of AnkiDroid. Its source baseline
is AnkiDroid **2.25.3** (`v2.25.3`); the exact commit and the files compared so
far are recorded in [ANKIDROID_UPSTREAM.md](ANKIDROID_UPSTREAM.md).

## Current port scope

The current port includes six source-mapped slices: deck-picker behavior, the
headless review-session lifecycle, reviewer count/next-time presentation
models, the answer-timer state machine, reviewer Auto Advance, and the
headless reviewer gesture parser.

- Deck-picker search: token and deck-path matching, with locale-invariant query
  casing and locale-aware deck-name casing, including contextual
  and expanding Unicode mappings, Turkish/Azeri/Lithuanian special cases, and
  partial `:` / `::` searches;
- Deck-picker rows and due count: flattening a deck tree into visible rows,
  including ancestor paths, collapsed decks, counts, and selection state, plus
  the source-equivalent total due count across top-level decks.
- Review session: a headless flow that loads the scheduler's current card, shows
  its question or answer, forwards an Again/Hard/Good/Easy rating, then loads
  the next queue item. It waits for the current card's state-mutation hook
  before revealing or grading it, and pauses for a scheduler timebox event
  before showing the queued card. The previously displayed side remains visible
  during the timebox and while a queue read loads or retries. A failed queue
  read can be retried without sending the completed card's rating again.
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

The implementation lives in `lib/` as a Dart library. The review flow requires
a `ReviewScheduler` adapter that supplies queue items, backend counts and active
queue, timebox events, and rating application. Auto Advance requires an
`AutoAdvanceSettingsAdapter` that loads all five settings for the current card's
deck; the model does not read collection storage or supply deck-config defaults.
`ReviewNextStateDescriber`
forwards the opaque scheduling state to the pinned backend's
`describeNextStates()` API. The session exposes the timebox's elapsed-time limit
and answer count, and can reload the queue when the caller continues. The
AnkiDroid 2.25.3 source pins
`io.github.david-allison:anki-android-backend` version `0.1.68-anki26.05`; the
Rust backend, collection storage, timebox calculation, and scheduling algorithm
are still external and are not implemented here. This is not yet a complete
AnkiDroid replacement: Android screens and platform lifecycle integration,
answer-timer widget/tick rendering, Auto Advance settings controls and reviewer
action routing, study-count and answer-button widgets/layout, next-time
visibility preference wiring, template rendering and media, timebox
presentation, leech handling, reviewer undo/redo, the JavaScript custom-state
and gesture bridges, WebView state collection, gesture preferences and Android
timeout lookup, sync, import/export, and other app features remain to be ported.
The source project has thousands of files, so this repository does not claim
full feature parity.

The port preserves the source behavior for the covered slices, including search
and collapse quirks, reviewer action ordering, question/answer transitions, the
scheduler timebox gate, active-count selection, and direct display of backend
answer labels. The answer timer also keeps the source's upper-only elapsed-time
clamp, exact limit comparison, negative elapsed values, and nonpositive-limit
behavior. Scheduling rules and timebox calculation remain with the backend
adapter; this port does not intentionally correct upstream bugs. See the tests
and upstream mapping for the specific behaviors and source files. Auto Advance
preserves the integer action codes and invalid-code fallbacks, delays and
cancellation boundaries, and the same-side job-overwrite quirk.
The gesture model also keeps strict grid and diagonal boundaries, Float
threshold and coordinate behavior, and the stale same-side tap job when a
double tap cancels only the latest scheduled job. The caller supplies tap mode,
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
