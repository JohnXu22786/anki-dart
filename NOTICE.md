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
  `lib/src/review_session.dart` reflects its queue and answer entry points; the
  Rust scheduler implementation is not included.
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
- Dart adaptations, the review-session controller, and new test code are
  Copyright © 2026 John Tsui.

## Unicode property data

The locale-casing property ranges and full lowercase mappings in
`lib/src/unicode_15_case_data.dart` are derived from Unicode 15.0.0
`UnicodeData.txt`, `PropList.txt`, `DerivedCoreProperties.txt`, and
`SpecialCasing.txt`, Copyright © 2022 Unicode, Inc. This data is distributed
under Unicode License V3. Its local SPDX identifier is
`LicenseRef-Unicode-License-V3`; the license text is included at
`LICENSES/Unicode-License-V3.txt`.

The adapted AnkiDroid source is licensed under GNU GPL version 3 or any later
version (`GPL-3.0-or-later`). The pinned scheduler binary is an external
dependency and is not redistributed here. See the notices in each source file
and the full license text in `COPYING` and `LICENSES/GPL-3.0-or-later.txt`.

The tests were written against the behavior documented and exercised by
AnkiDroid's `DeckFiltersTest.kt`, `DeckNodeTest.kt`, and reviewer flow. They are
not a port of the Android test harness.
