# AnkiDroid upstream source record

## `Collection.undoStatus()` backend projection

`collectionUndoStatus()` in `lib/src/collection_undo_status.dart` adapts
`Collection.undoStatus()` from
`libanki/src/main/java/com/ichi2/anki/libanki/Collection.kt:1168` in AnkiDroid
2.25.3, pinned to commit `d9bf072f814a0c37d30a694192593b31ff2df875`. It calls
the host's `getUndoStatus` once, reads the generic host status object's `undo`,
`redo`, and `lastStep` fields once each in source order, then uses the existing
`undoStatusFromFields()` conversion. Empty action strings become null; other
values pass through. Callback and field getter failures propagate unchanged.
The host retains Collection, backend, generated protobuf types and ownership.
`BackendUndo.kt` declares `GPL-3.0-or-later`; `Collection.kt` declares
`GPL-3.0-or-later` and separately notes incorporated AGPL-licensed `browser.py`
code. This adapter only bridges the host call and field reads; it contains no
AGPL browser implementation. The Dart adaptation and tests are Copyright © 2026
John Tsui under `GPL-3.0-or-later`; root `COPYING` remains unchanged.

## `Collection.completeTagRaw(input)` byte forwarding

`lib/src/collection_complete_tag_raw.dart` and
`test/collection_complete_tag_raw_test.dart` adapt the
`Collection.completeTagRaw(input)` wrapper in `Tags.kt:177` from AnkiDroid
2.25.3, pinned to commit `d9bf072f814a0c37d30a694192593b31ff2df875`. The Dart
adapter passes the exact `Uint8List` once to the host callback, returns its
exact bytes, and propagates callback failures unchanged. Serialization, tag
completion, Collection, and backend behavior remain host-side. The source
caller is `AnkiDroid/src/main/java/com/ichi2/anki/pages/PostRequestHandler.kt:95`.
No direct pinned upstream test for this wrapper was found; focused Dart tests
are source-derived. `Tags.kt` credits Norbert Nagold (2011), Kostas Spyropoulos
(2012), and Houssam Salem (2014), and declares `GPL-3.0-or-later`. The Dart
adaptation and tests are Copyright © 2026 John Tsui under the same license.
Root `COPYING` remains byte-identical.

## `Tags.setCollapsed()` backend forwarding

`tagsSetCollapsed()` in `lib/src/tags_set_collapsed.dart` adapts
`Tags.setCollapsed(tag, collapsed)` from
`libanki/src/main/java/com/ichi2/anki/libanki/Tags.kt:55–60`, pinned to
AnkiDroid 2.25.3 commit `d9bf072f814a0c37d30a694192593b31ff2df875`. It calls the
host backend once as `setTagCollapsed(name: tag, collapsed: collapsed)`,
returns the exact result, and lets errors propagate unchanged. Browser/tree
state and backend behavior remain host-side. The source caller is
`ManageTagsViewModel.kt:97–112`, which updates its in-memory tree only after the
backend call. The pinned `ManageTagsViewModelTest.kt:140–170` covers expand and
collapse behavior, but no direct wrapper argument assertion was found; focused
Dart tests cover argument forwarding, call count, result identity, and exception
identity. `Tags.kt` is Copyright (c) 2011 Norbert Nagold,
Copyright (c) 2012 Kostas Spyropoulos, and Copyright (c) 2014 Houssam Salem,
and declares `GPL-3.0-or-later`. The Dart adaptation and tests are Copyright ©
2026 John Tsui under the same license. Root `COPYING` remains byte-identical.

## `Tags.findAndReplace()` backend forwarding

`tagsFindAndReplace()` in `lib/src/tags_find_and_replace.dart` adapts only
`Tags.findAndReplace(noteIds, search, replacement, regex, matchCase)` from
`libanki/src/main/java/com/ichi2/anki/libanki/Tags.kt`, pinned to AnkiDroid
2.25.3 commit `d9bf072f814a0c37d30a694192593b31ff2df875`. It invokes the host
backend callback once with the same note ID list and all four remaining values
unchanged and in source order, returns the exact callback result, and lets
failures propagate unchanged. Collection, backend, generated request/result
types, and mutation remain host-side. The pinned
`libanki/src/test/java/com/ichi2/anki/libanki/FinderTest.kt` verifies collection
find-and-replace counts and matching behavior, but has no direct callback
argument/order assertion for `Tags.findAndReplace()`; focused source-derived
Dart tests cover argument identity and values, call count, result identity, and
exception identity. `Tags.kt` credits Norbert Nagold (2011), Kostas
Spyropoulos (2012), and Houssam Salem (2014), and declares
`GPL-3.0-or-later`. The Dart adaptation and tests are Copyright © 2026 John
Tsui under the same license. Root `COPYING` remains byte-identical.

## Remaining `Tags` backend forwarding operations

`lib/src/tags_backend_operations.dart` adapts `Tags.all()`, `tree()`,
`clearUnusedTags()`, `bulkAdd(noteIds, tags)`, `bulkRemove(noteIds, tags)`,
`rename(old, new)`, `remove(spaceSeparatedTags)`, and
`reparent(tags, newParent)` from `libanki/src/main/java/com/ichi2/anki/libanki/Tags.kt`
in AnkiDroid 2.25.3, pinned to commit
`d9bf072f814a0c37d30a694192593b31ff2df875`. It invokes each host callback once,
preserves note ID list references, tag strings, and the reparent iterable,
maps `bulkAdd`/`bulkRemove` to
`addNoteTags(noteIds: ..., tags: ...)`/`removeNoteTags(noteIds: ..., tags: ...)`,
maps `rename` to `renameTags(currentPrefix: old, newPrefix: new)`, maps
`remove` to `removeTags(val: spaceSeparatedTags)`, and maps `reparent` to
`reparentTags(tags: ..., newParent: ...)`. Each wrapper returns the callback's
exact result and propagates its exact failure. Tag trees, search, mutation, and
backend behavior remain host-side. The pinned `CollectionTest.kt:164–170`
exercises bulk-add integration, `FinderTest.kt:149–153` exercises Finder flows,
and `ManageTagsViewModelTest.kt` covers clear/rename/remove integration; those
tests do not assert these wrapper-to-backend named argument mappings. Focused
Dart cases are source-derived. `Tags.kt` credits Norbert Nagold (2011), Kostas
Spyropoulos (2012), and Houssam Salem (2014), and declares
`GPL-3.0-or-later`. The Dart adaptation and tests are Copyright © 2026 John
Tsui under the same license. Root `COPYING` remains byte-identical.

## Key selection modifier filter

`disallowModifierKeyCodes()` in `lib/src/key_selection_dialog_utils.dart`
adapts `KeySelectionDialogUtils.disallowModifierKeyCodes()` from
`AnkiDroid/src/main/java/com/ichi2/anki/dialogs/KeySelectionDialogUtils.kt`,
pinned to AnkiDroid 2.25.3 commit `d9bf072f814a0c37d30a694192593b31ff2df875`.
The host supplies the exact Android `KeyEvent` values for SHIFT_LEFT,
SHIFT_RIGHT, CTRL_LEFT, CTRL_RIGHT, ALT_LEFT, ALT_RIGHT, META_LEFT,
META_RIGHT, and FUNCTION. Each factory call captures a fresh set snapshot and
returns whether a candidate integer is absent from it. Android key events,
platform constants, and UI remain host-side. Focused cases are in
`test/key_selection_dialog_utils_test.dart`; the pinned upstream
`KeyPickerTest.kt` checks modifier rejection through the UI validator, while
the Dart tests cover the standalone predicate contract. The Kotlin source
declares `GPL-3.0-or-later` and has no separate copyright line. The Dart
adaptation and tests are Copyright © 2026 John Tsui under the same license.
Root `COPYING` remains byte-identical.

## Non-leading-zero input filter decision

`nonLeadingZeroInputFilter()` in `lib/src/non_leading_zero_input_filter.dart`
ports the pure replacement decision from
`AnkiDroid/src/main/java/com/ichi2/anki/ui/NonLeadingZeroInputFilter.kt`, pinned
to AnkiDroid 2.25.3 commit `d9bf072f814a0c37d30a694192593b31ff2df875`. It
replaces the selected destination range with the selected source range, then
returns an empty replacement only when the result has more than one UTF-16 code
unit and starts with ASCII `0`; otherwise it returns null to accept the source.
Android `InputFilter`/`Spanned` behavior, widgets, and text delivery remain
host-side. The Kotlin source declares `GPL-3.0-or-later` and has no separate
copyright line. The Dart adaptation and focused source-derived tests are
Copyright © 2026 John Tsui under the same license. Root `COPYING` remains
byte-identical.

## ViewModel delayed initialization

`InitStatus` and `projectViewModelDelayedInit()` in
`lib/src/view_model_delayed_initializer.dart` adapt
`AnkiDroid/src/main/java/com/ichi2/anki/utils/ViewModelUtils.kt`, pinned to
AnkiDroid 2.25.3 commit `d9bf072f814a0c37d30a694192593b31ff2df875`. The
contract is used by
`AnkiDroid/src/main/java/com/ichi2/anki/dialogs/ChangeNoteTypeViewModel.kt:152,280–300`
to expose delayed model initialization progress. The Dart projection passes its
work closure to the host launch callback, preserving deferred scheduling, then
publishes InProgress before the try region and mirrors the source's debug logs,
success publication, and Exception handling. Host scheduling, StateFlow,
ViewModel lifecycle, and Timber remain host-side. Focused cases are in
`test/view_model_delayed_initializer_test.dart`; no direct pinned test for
`ViewModelUtils.kt` was found. The Kotlin source declares `GPL-3.0-or-later` and
has no separate copyright line. The Dart adaptation and tests are Copyright ©
2026 John Tsui under the same license. Root `COPYING` remains byte-identical.

## `DeckOptionsDestination` model, factories, and `toIntent(context)`

`DeckOptionsDestination`, `DeckOptionsEntry`, and their factory/Intent
adapters in `lib/src/deck_options_destination.dart` are source-derived from
`anki-common/src/main/kotlin/com/ichi2/anki/common/destinations/DeckOptionsDestination.kt:9–28`
and
`AnkiDroid/src/main/java/com/ichi2/anki/pages/DeckOptionsDestination.kt:13–36`,
pinned to AnkiDroid 2.25.3 commit
`d9bf072f814a0c37d30a694192593b31ff2df875`. The Dart model preserves each deck
ID, filtered flag, nullable entry name, options list order and reference, and
the empty-options default. `fromDeckId` checks filtered state exactly once
with the supplied ID. `fromCurrentDeck` resolves the current ID before checking
that same ID once. Callback errors propagate unchanged and prevent later
calls. `toIntent(context)` delegates exactly once to the filtered or ordinary
host builder based on `isFiltered`, passing the same context and deck ID and
returning its exact result. Android collection access, Context, Intent, and UI
behavior remain host-side. Focused source-derived cases are in
`test/deck_options_destination_test.dart`; the pinned Kotlin source has no
matching tests for these adapter call sequences. The Kotlin sources declare
`GPL-3.0-or-later`; that attribution identifies the upstream Kotlin source and
does not claim authorship of the Dart adaptation. The Dart implementation and
tests are Copyright © 2026 John Tsui under the same license. Root `COPYING`
remains byte-identical.

## `NoteEditorDestination.AddNote.toIntent(context)`

`noteEditorAddNoteToIntent()` in `lib/src/note_editor_add_note_to_intent.dart`
adapts the `AddNote` branch of `NoteEditorDestination.toIntent(context)` from
`AnkiDroid/src/main/java/com/ichi2/anki/noteeditor/NoteEditorDestination.kt:18–22`,
pinned to AnkiDroid 2.25.3 commit
`d9bf072f814a0c37d30a694192593b31ff2df875`. The host callback creates one
`NoteEditorActivity` Intent; the adapter writes `CALLER` with the
`DECKPICKER` code (`3`), then writes the exact non-null deck ID once as a Long
extra under `DECK_ID`, and returns the same Intent. Null skips only the deck ID
write; zero and negative IDs are preserved. Callback failures propagate and
stop subsequent operations. Context, Android Intent and Activity construction,
and typed extras remain host-side. Focused source-derived cases are in
`test/note_editor_add_note_to_intent_test.dart`. The pinned
`AnkiDroid/src/test/java/com/ichi2/anki/NoteEditorTest.kt` covers launching
AddNote with a supplied deck ID and verifying deck selection; it does not cover
the adapter's callback mechanics. The Kotlin source declares
`GPL-3.0-or-later` and carries SPDX Copyright (c) 2024 Sanjay Sargam; that
attribution identifies the Kotlin source and does not claim authorship of the
Dart adaptation. The Dart implementation and tests are Copyright © 2026 John
Tsui under the same license. Root `COPYING` remains byte-identical.

## `NoteEditorDestination.AddInstantNote.toIntent(context)`

`noteEditorAddInstantNoteToIntent()` in
`lib/src/note_editor_add_instant_note_to_intent.dart` adapts the
`AddInstantNote` branch of `NoteEditorDestination.toIntent(context)` from
`AnkiDroid/src/main/java/com/ichi2/anki/noteeditor/NoteEditorDestination.kt:28–33`,
pinned to AnkiDroid 2.25.3 commit
`d9bf072f814a0c37d30a694192593b31ff2df875`. The host callback creates one
`NoteEditorActivity` Intent; the adapter writes `CALLER` with the
`INSTANT_NOTE_EDITOR` code (`14`), then always writes the exact `sharedText`
string, including an empty string, under Android's `Intent.EXTRA_TEXT` key
(`android.intent.extra.TEXT`), and returns that same Intent. Context, Android
Intent and Activity construction, and typed extra writes remain host-side;
callback failures propagate and stop subsequent operations. Focused
source-derived cases are in
`test/note_editor_add_instant_note_to_intent_test.dart`. The Kotlin source
declares `GPL-3.0-or-later` and carries SPDX Copyright (c) 2024 Sanjay Sargam;
that attribution identifies the Kotlin source and does not claim authorship of
the Dart adaptation. The Dart implementation and tests are Copyright © 2026
John Tsui under the same license. Root `COPYING` remains byte-identical.

## `CardInfoDestination.toIntent(context)`

`CardInfoDestination.toIntent()` in `lib/src/card_info_destination.dart`
adapts `CardInfoDestination.toIntent(context)` from
`AnkiDroid/src/main/java/com/ichi2/anki/pages/CardInfoDestination.kt:15–55`,
pinned to AnkiDroid 2.25.3 commit
`d9bf072f814a0c37d30a694192593b31ff2df875`. Its typed model preserves the exact
card ID and one of `CURRENT_CARD_STUDY`, `CURRENT_CARD_BROWSE`, or
`PREVIOUS_CARD_STUDY`. Host callbacks resolve that entry point's backend title
and matching sentence-case resource. The adapter strips every FSI and PDI
marker only for the sentence-case comparison; when that callback returns the
simplified title unchanged, the original title including its markers is
retained. It then creates one host Bundle, writes `title` before the `cardId`
Long, and delegates the exact Bundle and `CardInfoFragment` token to the host
Intent builder. Callback failures propagate and stop later operations.
Translations, Android Context, sentence-case resources, Bundle, fragment class,
Intent creation, and lifecycle behavior remain host-side. Source-derived cases
are in `test/card_info_destination_to_intent_test.dart`; the pinned source has no
test covering this projection. The Kotlin sources declare `GPL-3.0-or-later`;
that attribution identifies the upstream Kotlin source and does not claim
authorship of the Dart adaptation. The Dart implementation and tests are
Copyright © 2026 John Tsui under the same license. Root `COPYING` remains
byte-identical.

## `NoteEditorDestination.CopyNote.toIntent(context)`

`noteEditorCopyNoteToIntent()` in
`lib/src/note_editor_copy_note_to_intent.dart` adapts the `CopyNote` branch from
`AnkiDroid/src/main/java/com/ichi2/anki/noteeditor/NoteEditorDestination.kt:60–65`,
with the variant fields defined in
`anki-common/src/main/kotlin/com/ichi2/anki/common/destinations/NoteEditorDestination.kt:87–94`,
pinned to AnkiDroid 2.25.3 commit
`d9bf072f814a0c37d30a694192593b31ff2df875`. It creates one host Intent, then
writes `CALLER` with `NoteEditorCaller.NOTEEDITOR` (`8`), `DECK_ID` as a Long,
`CONTENTS` as the exact fields String, and `TAGS` as a fresh ordered copy of
the tag list, preserving empty lists and duplicates. It returns the same
Intent; callback failures propagate unchanged and stop later writes. Context,
`NoteEditorActivity`, Android Intent, typed extra handling, and JVM array
allocation remain host-side. Focused source-derived tests in
`test/note_editor_copy_note_to_intent_test.dart` cover ordered extras, empty
payloads, fresh tag-list projection, duplicates, Intent identity, and callback
failure short circuits. The pinned integration test
`AnkiDroid/src/test/java/com/ichi2/anki/NoteEditorTest.kt:330–350,903–908`
covers copy-note launch and the selected deck ID, but not all raw extras. The
Kotlin source declares `GPL-3.0-or-later` and has SPDX Copyright (c) 2024 Sanjay
Sargam; this identifies the Kotlin source only and does not attribute the Dart
adaptation to him. The Dart implementation and tests are Copyright © 2026 John
Tsui under the same license. Root `COPYING` remains byte-identical.

## `NoteEditorDestination.PassArguments.from(intent, extras)`

`noteEditorPassArgumentsFromIntent()` in
`lib/src/note_editor_pass_arguments_from_intent.dart` adapts the
`PassArguments.from(intent, extras)` projection from
`anki-common/src/main/kotlin/com/ichi2/anki/common/destinations/NoteEditorDestination.kt:106–121`,
pinned to AnkiDroid 2.25.3 commit
`d9bf072f814a0c37d30a694192593b31ff2df875`. It reads the supplied Intent's
action once and retains the exact caller-supplied extras Bundle. The caller
remains responsible for obtaining extras and performing the null check; Android
Intent and Bundle behavior remain host-side, and getter failures propagate
unchanged. Focused source-derived cases are in
`test/note_editor_pass_arguments_from_intent_test.dart`. The pinned app tests
cover PassArguments construction and `toIntent`, but no `from` factory tests.
The Kotlin source declares `GPL-3.0-or-later` and carries no distinct copyright
line. The Dart implementation and tests are Copyright © 2026 John Tsui under
the same license. Root `COPYING` remains byte-identical.

## `Decks.update(did, block)`

`decksUpdate()` in `lib/src/decks_update.dart` adapts
`Decks.update(did, block)` from
`AnkiDroid/src/main/java/com/ichi2/anki/utils/ext/Deck.kt`, pinned to AnkiDroid
2.25.3 commit `d9bf072f814a0c37d30a694192593b31ff2df875`. It calls the host
lookup once with the requested ID, applies the block to that exact non-null deck,
then saves that same deck. Kotlin's `!!` maps to Dart's `TypeError` from the `!`
null-check operator. Lookup failure or a null result skips the block and save;
a block failure skips save without rollback; save failures propagate after the
block. `Decks`, `Deck`, `DeckId`, collection/database access, and storage remain
host-side. No direct pinned test for this helper was found. The Dart adaptation
and focused tests are Copyright © 2026 John Tsui under `GPL-3.0-or-later`; the
Kotlin source declares `GPL-3.0-or-later` and has no separate copyright line.
Root `COPYING` remains byte-identical.

## `Decks.defaultConfig`

`deckDefaultConfig()` in `lib/src/deck_default_config.dart` adapts the
`Decks.defaultConfig` getter from
`AnkiDroid/src/main/java/com/ichi2/anki/utils/ext/Decks.kt`, pinned to AnkiDroid
2.25.3 commit `d9bf072f814a0c37d30a694192593b31ff2df875`. It calls the host
`getConfig` callback once with `confId: 1` and returns that exact result. The
Kotlin `!!` null failure maps to Dart's `TypeError` from the null-check operator.
Decks, deck configurations, collection/database access, and deck-picker UI
remain host-side. The pinned `DeckPickerTest.kt` exercises
`col.decks.defaultConfig` as integration coverage; no dedicated test for this
getter was found. The Dart adaptation and focused tests are Copyright © 2026 John
Tsui under `GPL-3.0-or-later`; the Kotlin source declares
`GPL-3.0-or-later` and has no separate copyright line. Root `COPYING` remains
byte-identical.

## `Int.clamp()`

`clampInt()` in `lib/src/int_clamp.dart` and its source-derived tests in
`test/int_clamp_test.dart` adapt `Int.clamp(minimumValue, maximumValue)` from
`AnkiDroid/src/main/java/com/ichi2/anki/utils/ext/Int.kt`, pinned to AnkiDroid
2.25.3 commit `d9bf072f814a0c37d30a694192593b31ff2df875`. The implementation
checks `value < minimumValue` first, then `value > maximumValue`, and otherwise
returns `value`. As the Kotlin documentation specifies, it does not validate
that the minimum is less than the maximum. Reversed bounds therefore preserve
the first matching branch rather than raising or normalizing the range. The
focused tests cover an interior value, both bounds, equal bounds, and a
reversed range where both comparisons match and the minimum is returned.

The AnkiDroid file carries the GPL-3.0-or-later notice and incorporates the
`_Ranges.kt` excerpt at line 1447 from Kotlin commit
`6ea9f879abd61ba9578b322eb07ff6a8450de11f`, Copyright 2010–2024 JetBrains
s.r.o. and Kotlin Programming Language contributors, under Apache-2.0. The
Dart adaptation and focused tests are Copyright © 2026 John Tsui and marked
`GPL-3.0-or-later`; both source/license notices are retained in the Dart file.
Root `COPYING` remains byte-identical.

## `Int.ifNotZero`

`intIfNotZero()` in `lib/src/int_if_not_zero.dart` and its source-derived cases
in `test/int_if_not_zero_test.dart` adapt `Int.ifNotZero` from
`common/src/main/java/com/ichi2/anki/common/utils/ext/Int.kt`, pinned to
AnkiDroid 2.25.3 commit `d9bf072f814a0c37d30a694192593b31ff2df875`. The source
returns without invoking the callback for zero; for nonzero values it invokes
the callback once with the receiver. Callback failures propagate unchanged.
The upstream file is marked `GPL-3.0-or-later` and has no separate copyright
line. The Dart adaptation and tests are Copyright © 2026 John Tsui and marked
`GPL-3.0-or-later`; root `COPYING` remains byte-identical.

## `List<T>.indexOfOrNull(predicate)`

`indexOfOrNull(predicate)` in `lib/src/list_index_of_or_null.dart` adapts the
predicate overload of `List<T>.indexOfOrNull(block)` from
`common/src/main/java/com/ichi2/anki/common/utils/ext/List.kt:18–21`, pinned to
AnkiDroid 2.25.3 commit `d9bf072f814a0c37d30a694192593b31ff2df875`. It visits
values in list order, calls the predicate once per visited value, returns the
first matching index without evaluating later values, and returns null when no
value matches (including an empty list). Predicate failures propagate
unchanged. Focused source-derived tests are in
`test/list_index_of_or_null_test.dart`. The source declares
`GPL-3.0-or-later` and has no distinct copyright line; its direct predicate
cases are in `common/src/test/java/com/ichi2/anki/common/utils/ext/ListTest.kt:17–23`.
The Dart implementation and tests are Copyright © 2026 John Tsui under the same
license. Root `COPYING` remains byte-identical.

## `MutableList<T>.swapPositions()`

`List.swapPositions(fromPosition, toPosition)` in `lib/src/mutable_list.dart`
adapts `MutableList<T>.swapPositions()` from
`AnkiDroid/src/main/java/com/ichi2/anki/utils/ext/MutableList.kt`, pinned to
AnkiDroid 2.25.3 commit `d9bf072f814a0c37d30a694192593b31ff2df875`. It mutates
the list by applying `Collections.swap` to adjacent positions in ascending order
when moving forward and descending order otherwise. It does not validate or
normalize positions. Equal positions ordinarily produce no swaps; the
`Int.MAX_VALUE` endpoint preserves Kotlin's signed-32-bit range overflow and
attempts a swap. Focused coverage is in `test/mutable_list_test.dart`. The
Kotlin source declares `GPL-3.0-or-later` with no separate copyright line; the
Dart adaptation and test are Copyright © 2026 John Tsui under the same license.
Root `COPYING` remains byte-identical.

## `MutableList<T>.replaceWith()`

`List.replaceWith(items)` in `lib/src/mutable_list.dart` adapts
`MutableList<T>.replaceWith(items)` from the same pinned `MutableList.kt` source.
The source clears the destination before calling `addAll`; the Dart adaptation
preserves that operation order by calling `clear()` before `addAll(items)`. As a
result, passing the destination itself clears it before consumption, and an
iteration failure leaves values already appended in place. Focused coverage is
in `test/mutable_list_test.dart`. The Kotlin source declares
`GPL-3.0-or-later` with no separate copyright line; the Dart adaptation and test
are Copyright © 2026 John Tsui under the same license. Root `COPYING` remains
byte-identical.

## `Double.wholeAndFraction()`

`wholeAndFraction()` in `lib/src/whole_and_fraction.dart` and its source-derived
cases in `test/whole_and_fraction_test.dart` adapt
`AnkiDroid/src/main/java/com/ichi2/anki/utils/ext/Double.kt` from AnkiDroid
2.25.3 commit `d9bf072f814a0c37d30a694192593b31ff2df875`. The source computes
`whole = this.toLong()`, then `fraction = this - whole`, and returns
`Pair(whole, fraction)`; the Dart named record preserves these fields and this
operation order. Its `whole` field is `BigInt` rather than `int`, preserving the
full JVM Long on JavaScript and the Dart VM. The conversion truncates finite
in-range values toward zero,
maps NaN to zero, and saturates infinities and out-of-range values to signed
64-bit Long bounds. The subtraction then uses binary64 arithmetic, including
the conversion of the saturated Long back to double. The focused tests exercise
signed fractional inputs, negative zero, NaN, infinities, both Long bounds, and
remainder calculation beyond those bounds. No direct test for this upstream
extension was found in the pinned checkout. The upstream source declares
`GPL-3.0-or-later` and Copyright © 2026 Shaan Narendran
<shaannaren06@gmail.com>; the Dart adaptation and test are Copyright © 2026
John Tsui and marked `GPL-3.0-or-later`. Root `COPYING` remains byte-identical.

## Signed Long parity on JavaScript

The selected helpers preserve Kotlin/JVM signed `Long` behavior while exposing
`BigInt` at Dart API boundaries wherever the full value range is required.
`lib/src/time_utils.dart` adapts `common/src/main/java/com/ichi2/anki/common/time/TimeUtils.kt`,
`Time.kt`, `MockTime.kt`, and the direct time tests. Clock values, calendar
milliseconds, duration milliseconds, `MockTime` state/Long additions, and whole
seconds returned by `intTime()` use `BigInt`; arithmetic wraps at 64 bits and
division truncates toward zero. `ReviewReminder` timestamps and deck IDs in
`lib/src/review_reminder.dart`, `review_reminder_form_state.dart`,
`review_reminder_schema_migration.dart`, and `schedule_reminders_destination.dart`
are also `BigInt`. The `ReviewReminderGroup` codecs preserve signed Long tokens
before `jsonDecode` can round them, emit exact decimal JSON number tokens, and
reject values outside Long bounds. Tests in `test/time_*_test.dart`,
`test/gen_today_test.dart`, `test/int_time_test.dart`, and the reminder codec
tests cover signed bounds, values above 2^53, wraparound, round trips, and
overflow rejection; `test/web_int64_smoke.dart` asserts exact outputs under
Node after JavaScript compilation. DateTime conversion is supported only within
the runtime DateTime range and throws `RangeError` outside that range.
`lib/src/note_object_methods.dart` also accepts `BigInt` IDs for Long equality
and the JVM 32-bit hash fold. These BigInt-facing signatures are a public API
change needed for exact web values. Upstream sources use the AnkiDroid 2.25.3
baseline commit `d9bf072f814a0c37d30a694192593b31ff2df875`; source attribution
and license details are recorded in `NOTICE.md`. Root `COPYING` remains
byte-identical.

This repository is a partial, modified Dart port of AnkiDroid 2.25.3. The
upstream source baseline is commit
`d9bf072f814a0c37d30a694192593b31ff2df875` from
[AnkiDroid](https://github.com/ankidroid/Anki-Android). This file records
source scopes for mapped units; additional unit summaries are in the repository
README and NOTICE.

## JavaScript add-on manifest projection

The Dart unit in `lib/src/addon_model.dart` adapts these pinned source files:

- `AnkiDroid/src/main/java/com/ichi2/anki/jsaddons/AddonData.kt`: nullable
  parsed manifest fields, `DistInfo`, and `getAddonModelFromAddonData()`.
- `AnkiDroid/src/main/java/com/ichi2/anki/jsaddons/AddonModel.kt`:
  validated `AddonModel` value.
- `AnkiDroid/src/main/java/com/ichi2/anki/jsaddons/AddonsConst.kt`: only
  `ANKIDROID_JS_ADDON_KEYWORDS`, `REVIEWER_ADDON`, and `NOTE_EDITOR_ADDON`.
- `AnkiDroid/src/main/java/com/ichi2/anki/AnkiDroidJsAPIConstants.kt`: only
  `CURRENT_JS_API_VERSION` (`0.0.3`).

The Dart projection keeps the source's early nullable/blank required-field
check, its subsequent npm-name, type, note-editor icon, keyword, and API-version
validation order, exact error messages, callback boundaries, optional metadata
defaults, reviewer icon, and nullable/passed-through `dist`. Kotlin whitespace
checks use UTF-16 code-unit semantics through the existing Dart
`trimKotlinWhitespace()` helper. It calls the already ported
`validateNpmPackageName()` with host-provided lowercase, URL-encoding, and log
callbacks.

The pinned direct cases in
`AnkiDroid/src/test/java/com/ichi2/anki/jsaddons/AddonModelTest.kt` include
missing name, keywords, and version; invalid add-on type; missing `dist`; and
missing optional metadata. Those pure `getAddonModelFromAddonData()` cases and
the successful projection values are covered by `test/addon_model_test.dart`.
The upstream JSON-file valid/invalid mapping tests,
unreadable-file handling, and URL-list loading are not ported here. Parsing
`package.json`, ignoring unknown JSON keys, file read/decode errors, add-on
directory listing, URL parsing/fetching, HTTP, Timber listing logs, and
filesystem behavior remain the host's responsibility. This unit does not port
`getAddonModelFromJson()` or `getAddonModelListFromJson()`.

`AddonData.kt`, `AddonModel.kt`, `AddonsConst.kt`, and the pinned test declare
`GPL-3.0-or-later` and Copyright © 2021 Mani <infinyte01@gmail.com>.
`AnkiDroidJsAPIConstants.kt` carries its GPL license notice and Copyright
© 2020 Mani <infinyte01@gmail.com>. The Dart adaptation and focused test are
Copyright © 2026 John Tsui and marked `GPL-3.0-or-later`. Root `COPYING` is
unchanged.

## Card type name value

`lib/src/card_type_name.dart` adapts `CardTypeName` from
`AnkiDroid/src/main/java/com/ichi2/anki/notetype/CardTypeName.kt`, pinned to
AnkiDroid 2.25.3 commit `d9bf072f814a0c37d30a694192593b31ff2df875`. It retains
the private constructor and `fromString(value)` factory, trims with Kotlin
`String.trim()` whitespace rules, compares retained strings with Kotlin/JVM
`String.equals(ignoreCase = true)`, independently hashes the retained
`String.lowercase()` result using Kotlin/JVM string hashing, and returns the
trimmed spelling from `toString()`. Equality and hashing intentionally follow
those separate source operations, including their Unicode edge behavior. The
case-insensitive comparison uses the repository's Unicode 15 simple BMP case
mapping tables to model the JVM's UTF-16 character comparison.

The source has an SPDX `GPL-3.0-or-later` notice and no separate copyright
line. The focused Dart cases are in `test/card_type_name_test.dart`; the pinned
source tree has no dedicated `CardTypeName` test. Card template editing,
duplicate-name discovery and resolution, rename UI and localization, and
backend/persistence operations remain host-side. This wrapper does not validate
names or impose uniqueness policy. The Dart adaptation and focused test are
Copyright © 2026 John Tsui and marked `GPL-3.0-or-later`. Root `COPYING` is
unchanged.

## `CharSequence.ifNullOrEmpty()`

`ifNullOrEmpty()` in `lib/src/char_sequence_if_null_or_empty.dart` and its
source-derived tests in `test/char_sequence_if_null_or_empty_test.dart` adapt
`<C : CharSequence> C?.ifNullOrEmpty(defaultValue: () -> C)` from
`AnkiDroid/src/main/java/com/ichi2/anki/utils/ext/CharSequence.kt`, pinned to
AnkiDroid 2.25.3 commit `d9bf072f814a0c37d30a694192593b31ff2df875`. The helper
accepts an opaque generic value and a host-provided emptiness callback, keeping
the Kotlin `CharSequence` implementation host-side while preserving exact
object identity for nonempty inputs and fallback results. Null skips the
emptiness callback; a nonnull value is checked once. The fallback runs once only
for null or empty inputs, in source order, and callback exceptions propagate
unchanged. The pinned source declares
`GPL-3.0-or-later` and has no separate copyright line; the Dart adaptation and
focused tests are Copyright © 2026 John Tsui and marked `GPL-3.0-or-later`.
Root `COPYING` remains byte-identical.

## String search normalization

`normalizeForSearch()` in `lib/src/string_normalization.dart` adapts
`String.normalizeForSearch()` from
`AnkiDroid/src/main/java/com/ichi2/anki/utils/ext/String.kt`, pinned to
AnkiDroid 2.25.3 commit `d9bf072f814a0c37d30a694192593b31ff2df875`. It applies
NFD, then removes only runs in the `InCombiningDiacriticalMarks` block
(U+0300..U+036F). Focused cases in
`test/string_normalization_test.dart` include the five direct examples from
`StringNormalizationTest.kt`, block boundaries, decomposition that preserves marks outside the block, and
UTF-16 surrogates. The host JVM supplies its runtime's normalization data; Dart pins
`unorm_dart` 0.3.3 with Unicode 18.0.0 data. Marks outside the specified block
remain. The upstream source and direct test copyrights and dependency license
obligations are recorded in `NOTICE.md`; root `COPYING` remains unchanged.

## NotetypeJson.getAllClozeTextFields

`getAllClozeTextFields()` in `lib/src/notetype_cloze_text_fields.dart` adapts
`AnkiDroid/src/main/java/com/ichi2/anki/utils/ext/NoteType.kt:getAllClozeTextFields()`
at AnkiDroid 2.25.3 commit
`d9bf072f814a0c37d30a694192593b31ff2df875`. The pinned
`AnkiDroid/src/test/java/com/ichi2/utils/NoteTypeTest.kt:testGetAllClozeTexts`
provides the direct example for `type:cloze:` and `cloze:` markers. The Dart
projection takes only the host `isCloze` flag and template question-format
strings: it checks the cloze guard before reading the sole `qfmt`, then returns
the regex's first capture from every non-overlapping match in source order.
Its optional-prefix atom explicitly excludes CR, LF, NEL, LS, and PS so Dart
matches Kotlin/JVM's default dot behavior. Rust `NotetypeJson`, JSON parsing,
persistence, and backend access remain host-side.

The non-cloze guard maps Kotlin `IllegalStateException` to Dart `StateError`.
Dart `Iterable.single` also reports both zero and multiple formats as
`StateError`; Kotlin `single()` uses `NoSuchElementException` for zero and
`IllegalArgumentException` for multiple formats. This exception-class mapping
is documented at the Dart API. `NoteType.kt` declares
`SPDX-License-Identifier: GPL-3.0-or-later` and has no separate copyright line.
`NoteTypeTest.kt` is Copyright © 2024 Ashish Yadav and marked
`GPL-3.0-or-later`. The Dart adaptation and focused tests are Copyright © 2026
John Tsui under `GPL-3.0-or-later`; root `COPYING` remains byte-identical.

## `Translations.cardStatsNoCardClean()`

`cardStatsNoCardClean()` in `lib/src/card_stats_no_card_clean.dart` adapts
`Translations.cardStatsNoCardClean()` from
`AnkiDroid/src/main/java/com/ichi2/anki/utils/ext/Translations.kt`, pinned to
AnkiDroid 2.25.3 commit `d9bf072f814a0c37d30a694192593b31ff2df875`. It invokes
the host callback that supplies `cardStatsNoCard()` exactly once, then applies
the source character class `[().]` globally, removing only literal ASCII
parentheses and periods. All other characters, whitespace, and line breaks are
preserved, and callback exceptions propagate unchanged. Android translation
resource loading remains host-side. No direct pinned test for this extension
was found; source-derived cases are in
`test/card_stats_no_card_clean_test.dart`. The Kotlin file declares
`GPL-3.0-or-later` and Copyright © 2025 lukstbit
<52494258+lukstbit@users.noreply.github.com>; the Dart adaptation and focused
tests are Copyright © 2026 John Tsui under `GPL-3.0-or-later`. Root `COPYING`
remains byte-identical.

## InputStream text conversion

`lib/src/input_stream_convert_to_string.dart` adapts
`InputStream.convertToString()` from
`AnkiDroid/src/main/java/com/ichi2/anki/utils/ext/InputStream.kt` at AnkiDroid
2.25.3 commit `d9bf072f814a0c37d30a694192593b31ff2df875`. It preserves the
source order: create the reader inside the try block, read and append each line
without separators, close after EOF, then publish the accumulated text. An
exception before publication discards all partial text. Kotlin's Java
`Exception` catch maps here to Dart `Exception`; warning callback failures and
Dart `Error` values propagate. The host supplies the Android
`InputStreamReader`/`BufferedReader`, default charset and 4096-character buffer,
byte decoding, stream closing, and Timber warning behavior. No direct pinned
test for this method was found. The Kotlin file declares
`SPDX-License-Identifier: GPL-3.0-or-later` and has no separate copyright line.
The Dart adaptation and focused tests are Copyright © 2026 John Tsui and marked
`GPL-3.0-or-later`; root `COPYING` remains byte-identical.

## `MutableStateFlow<T>.asVar()`

`MutableValue<T>`, `StateFlowVarDelegate<T>`, and `asVar()` in
`lib/src/state_flow_var_delegate.dart` adapt `MutableStateFlow<T>.asVar()` from
`AnkiDroid/src/main/java/com/ichi2/anki/utils/ext/MutableStateFlow.kt`, pinned
to AnkiDroid 2.25.3 commit `d9bf072f814a0c37d30a694192593b31ff2df875`. Each
`asVar()` call allocates a delegate retaining the exact mutable host object;
reads return that object's current `value`, and writes assign the supplied
value once. Kotlin's receiver and property metadata are accepted but ignored.
Dart has no Kotlin `by` syntax, so callers use `getValue()` and `setValue()`
explicitly. `MutableStateFlow` itself, emissions, conflation, dispatch, saved
state, Android ViewModels, and lifecycle behavior remain host-side. Focused
coverage is in `test/state_flow_var_delegate_test.dart`. The Kotlin source
declares `GPL-3.0-or-later` and has no separate copyright line; the Dart
adaptation and tests are Copyright © 2026 John Tsui under the same license.
Root `COPYING` remains byte-identical.

## `ReviewDeckDestination.toIntent(context)`

`ReviewDeckDestination.currentDeck` and
`ReviewDeckDestination.externalLaunch(deckId)` in
`lib/src/review_deck_destination.dart` adapt the `CurrentDeck` singleton and
`ExternalLaunch(deckId)` variant from
`anki-common/src/main/kotlin/com/ichi2/anki/common/destinations/ReviewDeckDestination.kt:10–26`,
and `toIntent(context)` from
`AnkiDroid/src/main/java/com/ichi2/anki/ReviewDeckDestination.kt:11–19`, pinned
to AnkiDroid 2.25.3 commit
`d9bf072f814a0c37d30a694192593b31ff2df875`. `CurrentDeck` delegates once to the
host `Reviewer.getIntent(context)` and returns its exact Intent. `ExternalLaunch`
creates one `IntentHandler` Intent, sets `Intent.ACTION_VIEW`, writes the exact
DeckId under `IntentHandler.EXTRA_DECK_ID`, then returns that same Intent; zero
and negative IDs are preserved. Callback failures propagate unchanged and stop
later operations. Reviewer screen selection, preferences, Activity selection,
Android Context, and Intent behavior remain host-side. Focused source-derived
tests in `test/review_deck_destination_test.dart` cover variant values, callback
order and identity, edge IDs, and failure short circuits. No direct pinned test
for these `toIntent` branches was found. Both Kotlin files declare
`GPL-3.0-or-later` and have no separate copyright line. The Dart adaptation and
tests are Copyright © 2026 John Tsui under the same license. Root `COPYING`
remains byte-identical.

## `Scheduler.answerCard(card, states, rating)`

`lib/src/scheduler_answer_card.dart` and its focused cases in
`test/scheduler_answer_card_test.dart` adapt the extension
`Scheduler.answerCard(card, states, rating)` from
`AnkiDroid/src/main/java/com/ichi2/anki/utils/ext/Scheduler.kt`, pinned to
AnkiDroid 2.25.3 commit `d9bf072f814a0c37d30a694192593b31ff2df875`. The
projection invokes the host answer builder before reading the recorded-answer
counter, increments once using signed 32-bit Kotlin `Int` wrap semantics, writes
once, and returns the exact answer object. Builder, getter, and setter failures
propagate in that source order. Scheduler, card/state/rating types, answer
construction, and the backend remain host-side. `Scheduler.kt` declares
`GPL-3.0-or-later` and has no separate copyright line; the Dart adaptation and
tests are Copyright © 2026 John Tsui under the same license. Root `COPYING`
remains byte-identical.

## `FragmentActivity.setFragmentResultListener(requestKey, listener)`

`fragmentActivitySetFragmentResultListener()` in
`lib/src/fragment_activity_set_fragment_result_listener.dart` adapts
`FragmentActivity.setFragmentResultListener(requestKey, listener)` from
`AnkiDroid/src/main/java/com/ichi2/anki/utils/ext/FragmentResult.kt`, pinned to
AnkiDroid 2.25.3 commit `d9bf072f814a0c37d30a694192593b31ff2df875`. It resolves
the current support FragmentManager once, then forwards the exact request key,
activity receiver as lifecycle owner, and listener callback in source order.
The adapter returns Dart `void`, corresponding to the Kotlin extension's
`Unit`; callback failures propagate unchanged and stop later work. Android
FragmentActivity, FragmentManager, Bundle, AndroidX lifecycle, and actual
result delivery remain host-side. No direct pinned test was found; focused
source-derived coverage is in
`test/fragment_activity_set_fragment_result_listener_test.dart`. The Kotlin
source declares `GPL-3.0-or-later` and Copyright © 2025 lukstbit
<52494258+lukstbit@users.noreply.github.com>. The Dart adaptation and tests are
Copyright © 2026 John Tsui under the same license. Root `COPYING` remains
byte-identical.

## `Fragment.isCompactWidth`

`fragmentIsCompactWidth()` in `lib/src/fragment_is_compact_width.dart` adapts
`Fragment.isCompactWidth` from
`AnkiDroid/src/main/java/com/ichi2/anki/utils/ext/Fragment.kt:26–47`, pinned to
AnkiDroid 2.25.3 commit `d9bf072f814a0c37d30a694192593b31ff2df875`. It obtains
the host Fragment's `screenWidthDp` once and returns whether that value is
strictly below 600. The required callback represents
`requireContext().resources.configuration.screenWidthDp`; no fallback or
clamping is added, and callback failures propagate unchanged. Android Fragment,
Context, Resources, Configuration, and lifecycle remain host-side. No direct
pinned test was found; focused source-derived tests are in
`test/fragment_is_compact_width_test.dart`. The Kotlin source declares
`GPL-3.0-or-later` and has no separate copyright line. The Dart adaptation and
tests are Copyright © 2026 John Tsui under the same license. Root `COPYING`
remains byte-identical.

## `LauncherDestination.toIntent(context)`

`LauncherDestination.instance.toIntent()` in
`lib/src/launcher_destination_to_intent.dart` adapts
`LauncherDestination.toIntent(context)` from
`AnkiDroid/src/main/java/com/ichi2/anki/LauncherDestination.kt:9–14`, pinned to
AnkiDroid 2.25.3 commit
`d9bf072f814a0c37d30a694192593b31ff2df875`. It creates one host Intent with the
exact supplied context and target token, then sets the supplied action token,
adds the supplied category token, and returns the identical Intent. Callback
failures propagate unchanged and stop subsequent operations. The host supplies
the equivalent of `IntentHandler::class.java`, `Intent.ACTION_MAIN`, and
`Intent.CATEGORY_LAUNCHER`; it does not add flags or resolve or change the
component. Android Intent semantics and launcher handling remain host-side. No
direct pinned test for this method was found; focused source-derived cases are in
`test/launcher_destination_to_intent_test.dart`. The Kotlin source declares
`GPL-3.0-or-later` and has no separate source copyright line. The Dart
adaptation and tests are Copyright © 2026 John Tsui under the same license.
Root `COPYING` remains byte-identical.

## `ChangelogDestination.toIntent(context)`

`ChangelogDestination.instance.toIntent()` in
`lib/src/changelog_destination_to_intent.dart` adapts the common singleton
`ChangelogDestination` from
`anki-common/src/main/kotlin/com/ichi2/anki/common/destinations/ChangelogDestination.kt:6`
and its `toIntent(context)` projection from
`AnkiDroid/src/main/java/com/ichi2/anki/InfoDestination.kt:10`, pinned to
AnkiDroid 2.25.3 commit
`d9bf072f814a0c37d30a694192593b31ff2df875`. It delegates once to the host
Intent builder with the exact supplied context and `Info::class.java` token,
then returns the exact callback result; callback failures propagate unchanged.
Android Context, the Info activity class, Intent construction, and Intent
behavior remain host-side. Focused source-derived tests in
`test/changelog_destination_to_intent_test.dart` cover singleton identity,
exact token and result identity, one callback invocation, and unchanged failure
propagation. No direct pinned test for this projection was found. The Kotlin
sources declare `GPL-3.0-or-later` and have no separate copyright line; this
identifies upstream provenance and does not claim authorship of the Dart
adaptation. The Dart implementation and tests are Copyright © 2026 John Tsui
under the same license. Root `COPYING` remains byte-identical.

## `BrowserDestination.toIntent(context)`

`lib/src/browser_destination.dart` and its source-derived cases in
`test/browser_destination_test.dart` adapt the four variants defined by
`anki-common/src/main/kotlin/com/ichi2/anki/common/destinations/BrowserDestination.kt:8–35`
and their `toIntent(context)` projection in
`AnkiDroid/src/main/java/com/ichi2/anki/browser/BrowserDestination.kt:10–27`,
pinned to AnkiDroid 2.25.3 commit
`d9bf072f814a0c37d30a694192593b31ff2df875`. The adapter creates a host
`CardBrowser` Intent for each call. `Open` adds no extras; `ToDeck` writes the
exact deck ID once; `ScrollToCard` writes deck ID then card ID; `Search` writes
the exact query then its Boolean all-decks value. Values such as empty queries,
zero and negative IDs pass through unchanged, callback order matches the source,
and a callback failure stops subsequent operations. Android Context, Intent,
`CardBrowser`, extra keys, typed writes, and Intent semantics remain host-side.
Both Kotlin source files declare `GPL-3.0-or-later` and have no separate
copyright line. This provenance identifies the Kotlin sources; the Dart
adaptation and tests are Copyright © 2026 John Tsui under the same license.
Root `COPYING` remains byte-identical.

## `PreferencesDestination.toIntent(context)`

`PreferencesDestination` and `toIntent()` in
`lib/src/preferences_destination.dart` adapt the three variants from
`anki-common/src/main/kotlin/com/ichi2/anki/common/destinations/PreferencesDestination.kt:6–18`
and their projection in
`AnkiDroid/src/main/java/com/ichi2/anki/preferences/PreferencesDestination.kt:11–18`,
pinned to AnkiDroid 2.25.3 commit
`d9bf072f814a0c37d30a694192593b31ff2df875`. Root delegates once to the host
root preferences Intent builder without a screen token. Advanced and
Accessibility delegate once to the host screen builder with the exact
`AdvancedSettingsFragment` and `AccessibilitySettingsFragment` class tokens,
respectively. Each branch returns the exact host result, and callback failures
propagate unchanged. Android Context, PreferencesActivity, fragment classes,
and Intent behavior remain host-side. Focused source-derived cases are in
`test/preferences_destination_test.dart`; the pinned Kotlin files have no
separate copyright line. This provenance identifies the upstream Kotlin
sources and does not claim authorship of the Dart adaptation. The Dart
implementation and tests are Copyright © 2026 John Tsui under
`GPL-3.0-or-later`; root `COPYING` remains byte-identical.

## Study options and statistics destination Intents

`StudyOptionsDestination` and `StatisticsDestination` in
`lib/src/study_options_destination_to_intent.dart` and
`lib/src/statistics_destination_to_intent.dart` adapt the common singleton
objects from
`anki-common/src/main/kotlin/com/ichi2/anki/common/destinations/StudyOptionsDestination.kt:6`
and
`anki-common/src/main/kotlin/com/ichi2/anki/common/destinations/StatisticsDestination.kt:6`,
respectively, pinned to AnkiDroid 2.25.3 commit
`d9bf072f814a0c37d30a694192593b31ff2df875`. Their host projections are
`AnkiDroid/src/main/java/com/ichi2/anki/StudyOptionsDestination.kt:10` and
`AnkiDroid/src/main/java/com/ichi2/anki/pages/StatisticsDestination.kt:11`.
Study Options calls the host equivalent of `Intent(context,
StudyOptionsActivity::class.java)`; Statistics calls the distinct host
equivalent of `SingleFragmentActivity.getIntent(context,
fragmentClass = Statistics::class)`. Both adapters pass the exact Context and
target token once, return the exact host result, and propagate callback failures
unchanged. Android Context, target classes, Activity, and Intent construction
remain host-side. Focused source-derived cases are in
`test/screen_destinations_test.dart`. Upstream integration coverage includes
`AnkiDroid/src/test/java/com/ichi2/anki/pages/StatisticsTest.kt:33–64` and
`AnkiDroid/src/test/java/com/ichi2/anki/reviewreminders/ReviewRemindersScreenshotTest.kt:138,278,303`;
no direct pinned test for either host `toIntent` projection was found. The Kotlin
sources declare `GPL-3.0-or-later` and have no separate copyright line; this
records upstream provenance and does not claim authorship of the Dart
adaptations. The Dart implementations and tests are Copyright © 2026 John Tsui
under the same license. Root `COPYING` remains byte-identical.

## Language locale parsing and RTL projection

`localeFromStringIgnoringScriptAndExtensions()` and `appLanguageIsRTL()` in
`lib/src/language_utils.dart` adapt
`AnkiDroid/src/main/java/com/ichi2/anki/LanguageUtils.kt:32–52`, pinned to
AnkiDroid 2.25.3 commit `d9bf072f814a0c37d30a694192593b31ff2df875`. Locale
parsing discards everything from the first `#`, retains Kotlin-compatible
underscore split fields, maps one through three fields to hyphenated tags, and
uses an empty tag for other field counts. The caller supplies the host Locale
constructor. RTL projection returns false for an empty display name; otherwise
it passes exactly the first UTF-16 code unit to the host Java Character
function and returns true only for right-to-left or right-to-left-Arabic
results. Locale construction and default-locale lookup remain host-side. The
pinned `LanguageUtilsTest.kt` tests app-language list contents but has no direct
test of these methods; `test/language_utils_test.dart` contains source-derived
cases for truncation, split boundaries, callback count, and directionality.
The Kotlin source declares `GPL-3.0-or-later` and carries Copyright (c) 2021
mikunimaru. The Dart adaptation and tests are Copyright © 2026 John Tsui under
the same license. Root `COPYING` remains byte-identical.

## Note field decorator

`aplicaHuevo()` in `lib/src/note_field_decorator.dart` ports the
platform-independent `NoteFieldDecorator.aplicaHuevo()` behavior from
`AnkiDroid/src/main/java/com/ichi2/utils/NoteFieldDecorator.kt`, pinned to
AnkiDroid 2.25.3 commit `d9bf072f814a0c37d30a694192593b31ff2df875`. It preserves
the source's ASCII ROT13 over UTF-16 code units, ordered encoded option and
emoji arrays, first-match short circuit, one bounded random-index call on a
match, exact decoration concatenation, and unchanged null, empty, or unmatched
field text. The host supplies Kotlin/JVM-compatible `String.equals(ignoreCase =
true)` and random index callbacks; concrete JVM comparison and randomness remain
host-side. Callback errors propagate and stop later work. Focused source-derived
tests are in `test/note_field_decorator_test.dart`; no direct pinned test was
found. The Kotlin source is Copyright © 2020 Mike Hardy and declares
`GPL-3.0-or-later`. The Dart adaptation and tests are Copyright © 2026 John Tsui
under the same license. Root `COPYING` remains byte-identical.

## `Note.numberOfCards(col)`, `cardIds(col)`, `cards(col)`, and `firstCard(col)`

`lib/src/note_card_queries.dart` and `test/note_card_queries_test.dart` adapt
these four methods from `libanki/src/main/java/com/ichi2/anki/libanki/Note.kt`
in AnkiDroid 2.25.3, pinned to commit
`d9bf072f814a0c37d30a694192593b31ff2df875` (lines 105–109 and 152). The host
retains Note, Collection, DB, and Card types and implementations. The adapter
forwards the current note ID once to `cardIdsOfNote` and returns that exact
list; `numberOfCards` delegates through the same card-ID adapter and reads its
size after success; `cards` eagerly resolves IDs in order and stops at the
first failing lookup; `firstCard` runs the exact source SQL once, forwards the
scalar ID once to `getCard`, and preserves query/card errors. Upstream marks
`numberOfCards` and `firstCard` with `@NotInPyLib`; `cardIds` and `cards` are not
marked. The pinned `NoteTest.kt` has no direct assertions for these methods.
`CollectionTest.kt` exercises `numberOfCards` and `cards` around generated
cards (lines 45–51, 127, and 199) and uses `firstCard` in a card lookup flow
(line 214); those integration assertions do not verify the exact SQL or
callback failure order. The focused Dart tests are source-derived adapter
contract tests, not Collection integration parity. `Note.kt` credits Norbert
Nagold (2011) and Houssam Salem (2014) and declares `GPL-3.0-or-later`. The Dart
adaptation and tests are Copyright © 2026 John Tsui under the same license.
Root `COPYING` remains byte-identical.

## AOSP `JSON.toString(value)`

`jsonToString()` in `lib/src/json_to_string.dart` adapts
`JSON.toString(value)` from
`AnkiDroid/src/main/java/com/ichi2/utils/JSON.kt`, pinned to AnkiDroid 2.25.3
commit `d9bf072f814a0c37d30a694192593b31ff2df875`. It returns a `String` input
unchanged, delegates a non-null non-String value to the required host callback
for Kotlin/JVM `Any.toString()`, and returns null without calling the callback
for null input. Callback results and failures pass through unchanged. The host
owns the concrete object representation and Kotlin/JVM-compatible conversion.
Focused cases are in `test/json_to_string_test.dart`; no direct pinned test for
this helper was found. The original helper is Copyright (C) 2010 The Android
Open Source Project and licensed under Apache-2.0; the license text is included
at `LICENSES/Apache-2.0.txt`. The Dart adaptation and tests are Copyright © 2026
John Tsui and distributed under this repository's GPL-3.0-or-later policy,
which is compatible with Apache-2.0. Root `COPYING` remains byte-identical.

## `Card.loadFromBackendCard(card)`

`loadCardFromBackend` in `lib/src/card_backend_load.dart` adapts the ordered
field assignment body of `Card.loadFromBackendCard(card)` from
`libanki/src/main/java/com/ichi2/anki/libanki/Card.kt` in AnkiDroid 2.25.3,
pinned to commit `d9bf072f814a0c37d30a694192593b31ff2df875` (lines 144–169).
The host supplies backend getters, type/queue decoders, render-output and note
cache clearing, and target setters; backend/protobuf and Card model types,
constructors, Collection access, and storage remain host-owned. It preserves
source order, optional presence-before-value checks, null assignment for absent
optionals, callback failure propagation, and already-applied earlier mutations.
The pinned `libanki/src/test/java/com/ichi2/anki/libanki/CardTest.kt` uses cards
loaded through backend integration, but has no direct assertions for this
ordered assignment, optional presence handling, or partial failure; focused
Dart tests are source-derived. `Card.kt` credits Daniel Svärd (2009), Norbert
Nagold (2011), and Houssam Salem (2014) and declares `GPL-3.0-or-later`. The Dart
adaptation and tests are Copyright © 2026 John Tsui under the same license.
Root `COPYING` remains byte-identical.

## LibAnki Card description

`lib/src/card_description.dart` and `test/card_description_test.dart` adapt `Card.toString()` (LibAnki alias `description`) from `libanki/src/main/java/com/ichi2/anki/libanki/Card.kt` in AnkiDroid 2.25.3, pinned to commit `d9bf072f814a0c37d30a694192593b31ff2df875` (lines 325–351). The host supplies declared fields in JVM order, field reads, value stringification, and a predicate identifying the two caught reflection exceptions; the Card model, JVM reflection, and runtime field discovery remain host-owned. The adapter preserves the full skip set, source formatting and delimiter, `N/A` for `IllegalAccessException` and `IllegalArgumentException`, and propagation of other failures. The pinned `libanki/src/test/java/com/ichi2/anki/libanki/CardTest.kt::test_toString` asserts that `Companion`, `SKIP_PRINT`, `note`, `renderOutput`, `col`, and `timerStarted` are absent. It does not assert `$assertionsDisabled`, field order, exact formatting or delimiter, or either reflection failure path; the additional focused Dart assertions are source-derived. `Card.kt` credits Daniel Svärd (2009), Norbert Nagold (2011), and Houssam Salem (2014), and declares `GPL-3.0-or-later`. The Dart adaptation and tests are Copyright © 2026 John Tsui under the same license. Root `COPYING` remains byte-identical.

## LibAnki Card equality and hash code

`lib/src/card_equality_hash_code.dart` adapts `Card.equals(other)` and `Card.hashCode()` from `libanki/src/main/java/com/ichi2/anki/libanki/Card.kt` in AnkiDroid 2.25.3, pinned to commit `d9bf072f814a0c37d30a694192593b31ff2df875` (lines 345–354). The host retains the Card class and ID access; the adapter compares host Card IDs, uses reference identity for non-Cards, and folds a signed Long ID to the signed JVM Int hash. Focused tests are in `test/card_equality_hash_code_test.dart`. The pinned `libanki/src/test/java/com/ichi2/anki/libanki/CardTest.kt` has no direct equality or hashCode assertions; these Dart tests are source-derived. `Card.kt` credits Daniel Svärd (2009), Norbert Nagold (2011), and Houssam Salem (2014), and declares `GPL-3.0-or-later`. The Dart adaptation and tests are Copyright © 2026 John Tsui under the same license. Root `COPYING` remains byte-identical.

## LibAnki Card shallow clone

`lib/src/card_clone.dart` and `test/card_clone_test.dart` adapt
`Card.clone()` from `libanki/src/main/java/com/ichi2/anki/libanki/Card.kt` in
AnkiDroid 2.25.3, pinned to commit
`d9bf072f814a0c37d30a694192593b31ff2df875` (lines 318–322). The host owns the
Card object, shallow-clone operation, Card cast, exception identification, and
`RuntimeException(cause)` construction. The adapter calls the host clone once,
returns the cast result, wraps only `CloneNotSupportedException` with the
exact caught cause, and propagates other failures unchanged. The pinned
`libanki/src/test/java/com/ichi2/anki/libanki/CardTest.kt` has no direct clone
test, so the focused Dart tests are source-derived. `Card.kt` credits Daniel
Svärd (2009), Norbert Nagold (2011), and Houssam Salem (2014) and declares
`GPL-3.0-or-later`. The Dart adaptation and tests are Copyright © 2026 John
Tsui under the same license. Root `COPYING` remains byte-identical.

## Field.setOrd JSON write

`lib/src/field_set_ord.dart` adapts only `Field.setOrd(value)` from
`libanki/src/main/java/com/ichi2/anki/libanki/Field.kt` in AnkiDroid 2.25.3,
pinned to commit `d9bf072f814a0c37d30a694192593b31ff2df875` (line 99). It
forwards one `put("ord", value ?: JSONObject.NULL)` call: non-null integers
pass through unchanged, null uses the identical host-provided sentinel, and
put failures propagate unchanged. JSONObject and its null sentinel remain
host-owned; the rest of the Field model is outside this adaptation. Focused
tests are in `test/field_set_ord_test.dart`. The pinned test tree has no
Field/Fields test file or direct `setOrd` assertion;
`CardTest.kt::test_gen_or` invokes `setOrd(null)` indirectly but does not assert
the exact write. `Field.kt` is Copyright © 2024 David Allison and declares
`GPL-3.0-or-later`. The Dart adaptation and tests are Copyright © 2026 John
Tsui under the same license. Root `COPYING` remains byte-identical.

## `Note.removeTag(tag)`

`lib/src/note_remove_tag.dart` adapts only `Note.removeTag(tag)` from
`libanki/src/main/java/com/ichi2/anki/libanki/Note.kt` in AnkiDroid 2.25.3,
pinned to commit `d9bf072f814a0c37d30a694192593b31ff2df875` (lines 238–252).
The host retains the Note model and mutable tag list and supplies
Kotlin/JVM-compatible `String.equals(ignoreCase = true)`. The helper calls that
comparison for every tag in order, passing the candidate tag first and the
requested tag second; it collects matches before removing each collected string
with exact list equality. This removes matching case variants and duplicates,
preserves unrelated tag order, and leaves the list unchanged if comparison
throws during collection. `NoteTest.kt` and `TagsTest.kt` have no direct
`removeTag` assertion; `CollectionTest.test_addDelTags` covers backend tag
addition/canonification and does not call this method. Focused Dart cases in
`test/note_remove_tag_test.dart` are source-derived. `Note.kt` credits Norbert
Nagold (2011) and Houssam Salem (2014) and declares `GPL-3.0-or-later`. The Dart
adaptation and tests are Copyright © 2026 John Tsui under the same license.
Root `COPYING` remains byte-identical.

## `Note.clone()`, `equals(other)`, and `hashCode()`

`lib/src/note_object_methods.dart` adapts these methods from
`libanki/src/main/java/com/ichi2/anki/libanki/Note.kt` in AnkiDroid 2.25.3,
pinned to commit `d9bf072f814a0c37d30a694192593b31ff2df875` (lines 273–287).
The host owns Note, runtime-class identity, ID access, shallow cloning, cast,
and `RuntimeException` construction. The adapters preserve the source's
reference-identity, null, and exact-class short-circuits; compare IDs only after
a same-class result; wrap only `CloneNotSupportedException` from shallow clone
with its exact cause; and fold the signed Long ID into the signed JVM Int hash.
The ID callbacks and hash helper use `BigInt` to preserve all Long bits on
JavaScript.
The pinned `NoteTest.kt` directly tests only `ClozeUtils.getNextClozeIndex`;
it has no direct clone, equals, or hashCode assertions. Focused Dart tests in
`test/note_object_methods_test.dart` are source-derived. `Note.kt` credits
Norbert Nagold (2011) and Houssam Salem (2014) under `GPL-3.0-or-later`. The
Dart adaptation and tests are Copyright © 2026 John Tsui under the same license.
Root `COPYING` remains byte-identical.

## `Note.hasTag`, `addTag`, `stringTags`, and `setTagsFromStr`

`lib/src/note_tag_wrappers.dart` adapts the four adjacent tag wrappers in
`libanki/src/main/java/com/ichi2/anki/libanki/Note.kt` from AnkiDroid 2.25.3,
pinned to commit `d9bf072f814a0c37d30a694192593b31ff2df875` (lines 224–263).
The host retains Note and Collection objects. `hasNoteTag` delegates once to
`inList(tag, noteTags)` and returns its Boolean; `addNoteTag` invokes the
mutable list's `add` once without deduplication; `stringNoteTags` passes the
exact `canonify` result to `join` and returns its string; and
`setNoteTagsFromStr` calls `split` once and passes its exact mutable list to the
host Note setter. Callback failures propagate unchanged. Existing Dart `Tags`
helpers are reused without modification.

The pinned `NoteTest.kt`, `TagsTest.kt`, and `NoteWithColTest.kt` contain no
direct assertions for these four Note wrappers. `TagsTest.kt` separately tests
`Tags.inList` and `Tags.split`, which does not cover the Note-level delegation,
ordering, result forwarding, or property replacement. Focused cases in
`test/note_tag_wrappers_test.dart` are source-derived. `Note.kt` credits Norbert
Nagold (2011) and Houssam Salem (2014) and declares `GPL-3.0-or-later`. The Dart
adaptation and tests are Copyright © 2026 John Tsui under the same license.
Root `COPYING` remains byte-identical.

## `Note.fieldsCheck(col)`

`lib/src/note_fields_check_wrapper.dart` adapts
`Note.fieldsCheck(col)` from `libanki/src/main/java/com/ichi2/anki/libanki/Note.kt`
in AnkiDroid 2.25.3, pinned to commit
`d9bf072f814a0c37d30a694192593b31ff2df875` (line 271). The host retains the
Note and Collection/backend objects, `toBackendNote()` conversion, response and
state types. The adapter calls the conversion once, forwards that exact backend
Note once, and returns the state read from the exact response; failures at each
callback propagate unchanged. `CollectionTest.kt::test_note_fields_check`
(lines 125–140) integration coverage asserts normal and non-normal results.
`NoteTest.kt` has no direct `fieldsCheck` assertion; focused Dart adapter tests
cover ordering, identity forwarding and exception propagation, not backend
integration parity. `Note.kt` credits Norbert Nagold (2011) and Houssam Salem
(2014) and declares `GPL-3.0-or-later`. The Dart adaptation and tests are
Copyright © 2026 John Tsui under the same license. Root `COPYING` remains
byte-identical.

## LibAnki Note backend loading

`lib/src/note_backend_load.dart` and `test/note_backend_load_test.dart` adapt
`Note.load(col)` and `loadFromBackendNote(col, note)` from
`libanki/src/main/java/com/ichi2/anki/libanki/Note.kt` in AnkiDroid 2.25.3,
pinned to commit `d9bf072f814a0c37d30a694192593b31ff2df875` (lines 82–102).
The adapter reads the current note ID, fetches once, and forwards that exact
backend Note. The projection retains the source order for ID, GUID, notetype ID,
required notetype lookup/unwrap, modification time, USN, copied tags, copied
fields, and final field-map construction. The Note, Collection/backend,
protobuf, Notetype, and Field remain host-side; callbacks own their reads,
setters, lookup/unwrap, list copies, and field-map creation. Failures stop at
their operation and retain previous target mutations. The pinned
`libanki/src/test/java/com/ichi2/anki/libanki/NoteTest.kt` has no direct
backend-load assertions. `CollectionTest.test_addDelTags` loads notes and
asserts resulting tags, but does not assert load order, fields, list-copy
identity, or partial mutation after callback failures. Focused Dart tests are
source-derived adapter contract tests rather than backend integration parity.
`Note.kt` credits Norbert Nagold (2011) and Houssam Salem (2014) and declares
`GPL-3.0-or-later`. The Dart adaptation and tests are Copyright © 2026 John Tsui
under the same license. Root `COPYING` remains byte-identical.

## LibAnki Note constructors and `fromNotetypeId`

`Note(col, id)`, `Note(col, backendNote)`, and `Note.fromNotetypeId(col, ntid)` in `lib/src/note_constructors.dart` and `test/note_constructors_test.dart` adapt AnkiDroid 2.25.3 `libanki/src/main/java/com/ichi2/anki/libanki/Note.kt`, pinned to commit `d9bf072f814a0c37d30a694192593b31ff2df875` (lines 63–80). The first constructor assigns the supplied ID before calling the existing load operation once; the backend-note constructor calls existing projection once with the identical supplied object. The factory calls backend `newNote(ntid)` once, passes that exact result to Note construction once, and returns the exact constructed Note. Callback errors stop subsequent operations and propagate unchanged. Note, Collection/backend, protobuf, and generated objects remain host-owned. The pinned `libanki/src/test/java/com/ichi2/anki/libanki/NoteTest.kt` tests Cloze utilities only and has no direct assertions for these constructors or factory. `CollectionTest.kt` creates notes through Collection helpers, but does not assert these exact callback sequences or object identities; the focused Dart tests are source-derived adapter contract tests, not backend integration parity. `Note.kt` credits Norbert Nagold (2011) and Houssam Salem (2014) and declares `GPL-3.0-or-later`. The Dart adaptation and tests are Copyright © 2026 John Tsui under the same license. Root `COPYING` remains byte-identical. See [ANKIIDROID_UPSTREAM.md](ANKIIDROID_UPSTREAM.md) and [NOTICE.md](NOTICE.md) for source mapping and attribution.

## `Note.ephemeralCard(col)` orchestration

`lib/src/note_ephemeral_card.dart` and `test/note_ephemeral_card_test.dart`
adapt only the orchestration in `Note.ephemeralCard()` from AnkiDroid 2.25.3
`libanki/src/main/java/com/ichi2/anki/libanki/Note.kt`, pinned to commit
`d9bf072f814a0c37d30a694192593b31ff2df875` (lines 111–147). The adapter
creates one host Card with a null ID, assigns its ordinal and deck ID, resolves
the supplied or current notetype, clones the supplied template or selects from
the host template list, sets the selected template ordinal, invokes the host
render callback once, and assigns the returned output and Note to the same
Card. Note, Collection, Card, notetype, template, clone behavior, render
context, and rendering remain host-side. Failures propagate unchanged and
stop later operations while preserving preceding mutations. The pinned
`libanki/src/test/java/com/ichi2/anki/libanki/NoteTest.kt` contains no direct
`ephemeralCard` assertion; the focused tests cover adapter callback order,
conditional lookup, template choice/cloning, identity, mutations, and
short-circuiting, not host rendering internals. `Note.kt` credits Norbert
Nagold (2011) and Houssam Salem (2014) and declares `GPL-3.0-or-later`. The Dart
adaptation and tests are Copyright © 2026 John Tsui under the same license.
TemplateManager rendering remains host-side; no AGPL source was copied. Root
`COPYING` remains byte-identical.

## `Note.setField(index, value)`

`lib/src/note_set_field.dart` and `test/note_set_field_test.dart` adapt only
`Note.setField(index, value)` from
`libanki/src/main/java/com/ichi2/anki/libanki/Note.kt` in AnkiDroid 2.25.3,
pinned to the verified `v2.25.3` commit
`d9bf072f814a0c37d30a694192593b31ff2df875` (lines 211–217). The source method
is annotated `@NotInPyLib`; its body assigns `fields[index] = value`. The Dart
adapter performs that one indexed assignment on the host fields list without
validation, clamping, copying, or normalization, leaving list bounds/type
semantics to the host and propagating its exact exceptions. The pinned
`libanki/src/test/java/com/ichi2/anki/libanki/NoteTest.kt` tests
`ClozeUtils.getNextClozeIndex` only and has no direct `setField` assertion.
Focused Dart tests verify the exact index/value and single setter call, backing
list mutation, and host exception identity; these are source-derived adapter
contract tests, not host-list integration parity. `Note.kt` credits Norbert
Nagold (2011) and Houssam Salem (2014) and declares `GPL-3.0-or-later`. The Dart
adaptation and tests are Copyright © 2026 John Tsui under the same license.
Root `COPYING` remains byte-identical.

## `Card.setUserFlag(flag)`

`cardSetUserFlag` in `lib/src/card_user_flag.dart`, exported through
`lib/anki_dart.dart`, adapts `Card.setUserFlag(flag)` from AnkiDroid 2.25.3
`libanki/src/main/java/com/ichi2/anki/libanki/Card.kt`, pinned to commit
`d9bf072f814a0c37d30a694192593b31ff2df875` (lines 361–370). The Kotlin body
is `flags = setFlagInInt(flags, flag)` and retains its existing `@RustCleanup`
marker. The host supplies the flags property callbacks; the Dart wrapper reads
flags once, calls the existing `setFlagInInt` once, and writes its result once
only after computation succeeds. Higher bits are preserved by that helper; its
validation and error remain unchanged. Getter, helper, and setter failures
propagate unchanged. No Card model, extra validation, or adjacent API changes
are introduced. The pinned
`libanki/src/test/java/com/ichi2/anki/libanki/FlagTest.kt` (lines 63–69)
directly calls `setUserFlag(2)`, then `3` and `0`, and checks `userFlag()`; it
does not cover wrapper ordering or callback/helper failures. Those additional
source-derived cases are in `test/card_user_flag_test.dart`. `Card.kt` credits
Daniel Svärd (2009), Norbert Nagold (2011), and Houssam Salem (2014), and
declares `GPL-3.0-or-later`. The Dart adaptation and tests are Copyright © 2026
John Tsui under the same license. Root `COPYING` remains byte-identical.

## `Collection.setWantsAbort()`

`collectionSetWantsAbort()` in `lib/src/collection_set_wants_abort.dart` adapts
only the deprecated no-argument wrapper and its `set_wants_abort` alias from
`libanki/src/main/java/com/ichi2/anki/libanki/Collection.kt:1280–1284`, pinned
to AnkiDroid 2.25.3 commit `d9bf072f814a0c37d30a694192593b31ff2df875`. It
invokes the host abort callback exactly once, returns void, and propagates
callback failures unchanged. Abort behavior remains host-side. No direct pinned wrapper test was found; focused Dart cases cover callback
count, the void function signature, and exception identity. `Collection.kt`
credits Norbert Nagold (2011), Kostas Spyropoulos (2012), and Ankitects Pty Ltd
(2022), and declares `GPL-3.0-or-later`. It separately notes incorporated
`AGPL-3.0-or-later` `browser.py` code; this adaptation contains only the GPL
wrapper and no browser implementation. The Dart adaptation and tests are
Copyright © 2026 John Tsui under the same license. Root `COPYING` remains
byte-identical.

## `Collection.setWantsAbortRaw(input)`

`collectionSetWantsAbortRaw()` in `lib/src/collection_set_wants_abort_raw.dart`
adapts only the byte-array forwarding wrapper in
`libanki/src/main/java/com/ichi2/anki/libanki/Collection.kt:1287`, pinned to
AnkiDroid 2.25.3 commit `d9bf072f814a0c37d30a694192593b31ff2df875`. It forwards
the exact `Uint8List` once to the host callback, returns the callback's exact
result, and propagates failures unchanged. Abort behavior, serialization, and
the backend protocol remain host-owned. The caller routes
`AnkiDroid/src/main/java/com/ichi2/anki/pages/PostRequestHandler.kt:105` to
this host method. No direct pinned test for the wrapper was found; focused Dart
tests are source-derived adapter contract tests. `Collection.kt` declares
`GPL-3.0-or-later` and carries source copyrights for Norbert Nagold (2011),
Kostas Spyropoulos (2012), and Ankitects Pty Ltd (2022). The file separately
notes incorporated AGPL-licensed browser.py code; this port contains only the
GPL forwarding wrapper and no browser.py implementation. The Dart adaptation
and tests are Copyright © 2026 John Tsui under the same license. Root `COPYING`
remains byte-identical.

## `Collection.replaceInSearchNode(existingNode, replacementNode)`

`collectionReplaceInSearchNode()` in `lib/src/collection_replace_search_node.dart`
adapts only the backend forwarding wrapper from
`libanki/src/main/java/com/ichi2/anki/libanki/Collection.kt:1038–1047`, pinned
to AnkiDroid 2.25.3 commit
`d9bf072f814a0c37d30a694192593b31ff2df875`. It passes the exact existing and
replacement SearchNode objects once to the host callback in their named roles,
returns the exact String, and propagates callback failures unchanged. SearchNode
construction, replacement semantics, and the backend remain host-owned; no AGPL
search/query implementation or source text is included. No direct pinned test
for this wrapper was found; focused Dart cases are source-derived adapter
contract tests. `Collection.kt` declares `GPL-3.0-or-later` and carries source
copyrights for Norbert Nagold (2011), Kostas Spyropoulos (2012), and Ankitects
Pty Ltd (2022). The Dart adaptation and tests are Copyright © 2026 John Tsui
under the same license. Root `COPYING` remains byte-identical.

## `Collection.getReviewLogs(cardId)` host forwarding

`collectionGetReviewLogs()` in `lib/src/collection_get_review_logs.dart` and
`test/collection_get_review_logs_test.dart` adapt the forwarding wrapper
`Collection.getReviewLogs(cardId)` from
`libanki/src/main/java/com/ichi2/anki/libanki/Collection.kt:1152`, pinned to
AnkiDroid 2.25.3 commit
`d9bf072f814a0c37d30a694192593b31ff2df875`. It passes the same card ID once to
the host callback and returns its exact generic `List<T>` result; callback
failures propagate unchanged. `CardId` is represented as Dart `int`, while
`StatsRevlogEntry` and backend/log-query behavior remain host-owned. No direct
pinned test or Dart caller for this wrapper was found; focused tests cover the
callback contract. `Collection.kt` declares `GPL-3.0-or-later` and credits
Norbert Nagold (2011), Kostas Spyropoulos (2012), and Ankitects Pty Ltd (2022).
It separately notes incorporated AGPL-3.0-or-later `browser.py` code; this
adapter copies only the GPL forwarding wrapper and no browser implementation.
The Dart adaptation and tests are Copyright © 2026 John Tsui under the same
license. Root `COPYING` remains byte-identical.

## `Collection.studiedToday()` host forwarding

`collectionStudiedToday()` in `lib/src/collection_studied_today.dart` and
`test/collection_studied_today_test.dart` adapt only the no-argument forwarding
wrapper `Collection.studiedToday()` from
`libanki/src/main/java/com/ichi2/anki/libanki/Collection.kt:1157`, pinned to
AnkiDroid 2.25.3 commit `d9bf072f814a0c37d30a694192593b31ff2df875`. It invokes
the host callback once, returns its exact `String`, and propagates callback
failures unchanged. The studied-today query and formatting stay host-side; the
source `RustCleanup("check sched.studiedToday")` marker does not change this
pinned behavior. No direct pinned test or Dart caller for this wrapper was
found; focused Dart tests cover its callback contract. `Collection.kt` credits
Norbert Nagold (2011), Kostas Spyropoulos (2012), and Ankitects Pty Ltd (2022),
and declares `GPL-3.0-or-later`. The file separately notes incorporated
`AGPL-3.0-or-later` `browser.py` code; this adapter copies only the GPL
forwarding wrapper and no browser implementation. The Dart adaptation and
tests are Copyright © 2026 John Tsui under the same license. Root `COPYING`
remains byte-identical.

## Collection custom undo entry forwarding

`collectionAddCustomUndoEntry()` and `collectionMergeUndoEntries()` in
`lib/src/collection_custom_undo_entry_operations.dart`, with focused cases in
`test/collection_custom_undo_entry_operations_test.dart`, adapt only
`Collection.addCustomUndoEntry(name)` and `Collection.mergeUndoEntries(target)`
from `libanki/src/main/java/com/ichi2/anki/libanki/Collection.kt:1181,1192` in
AnkiDroid 2.25.3, pinned to commit
`d9bf072f814a0c37d30a694192593b31ff2df875`. They pass the exact name or undo
step target to the host callback once, return the host integer or generic
result unchanged, and propagate callback failures. The host retains the undo
operations, state, and generated `OpChanges`. No direct pinned tests or Dart
callers for these wrappers were found; the focused Dart tests are
source-derived adapter contract tests. `Collection.kt` credits Norbert Nagold
(2011), Kostas Spyropoulos (2012), and Ankitects Pty Ltd (2022), and declares
`GPL-3.0-or-later`. It separately notes incorporated
`AGPL-3.0-or-later` `browser.py` code; this adaptation copies only the GPL
forwarding wrappers and no browser implementation. The Dart adaptation and
tests are Copyright © 2026 John Tsui under the same license. Root `COPYING`
remains byte-identical.

## `Collection.fixIntegrity()` host callback

`collectionFixIntegrity()` in `lib/src/collection_fix_integrity.dart` adapts
only the no-argument `Collection.fixIntegrity()` wrapper from
`libanki/src/main/java/com/ichi2/anki/libanki/Collection.kt:1257`, pinned to
AnkiDroid 2.25.3 commit `d9bf072f814a0c37d30a694192593b31ff2df875`. The wrapper
calls the host database-check callback once and returns its exact ordered
problem strings; callback failures propagate unchanged. Database access and
integrity checking remain host-owned. Focused Dart adapter tests are in
`test/collection_fix_integrity_test.dart`; no direct pinned wrapper test was
found. `Collection.kt` credits Norbert Nagold (2011), Kostas Spyropoulos
(2012), and Ankitects Pty Ltd (2022), declares `GPL-3.0-or-later`, and
separately notes incorporated `AGPL-3.0-or-later` `browser.py` code. This
adaptation contains only the GPL forwarding wrapper and no browser
implementation. The Dart adaptation and tests are Copyright © 2026 John Tsui
under the same license. Root `COPYING` remains byte-identical.

## `Collection.optimize()` SQL orchestration

`collectionOptimize()` in `lib/src/collection_optimize.dart` adapts only the
two SQL calls in `Collection.optimize()` from
`libanki/src/main/java/com/ichi2/anki/libanki/Collection.kt:1260–1263`, pinned
to AnkiDroid 2.25.3 commit `d9bf072f814a0c37d30a694192593b31ff2df875`. It
invokes the host database callback as `vacuum`, then `analyze`, exactly once
each. A failure from the first callback propagates unchanged and prevents the
second call. Database and SQLite behavior remain host-owned. No exact Dart
wrapper, direct pinned test, or caller was found in the source audit; focused
Dart tests are source-derived adapter contract tests. `Collection.kt` credits
Norbert Nagold (2011), Kostas Spyropoulos (2012), and Ankitects Pty Ltd (2022),
and declares `GPL-3.0-or-later`. It separately notes incorporated
`AGPL-3.0-or-later` `browser.py` code; this adapter copies only the two SQL
orchestration calls and no browser implementation. The Dart adaptation and
tests are Copyright © 2026 John Tsui under the same license. Root `COPYING`
remains byte-identical.

## Reviewer edited-tags operation

`executeReviewerEditedTags()` in `lib/src/reviewer_edited_tags_operation.dart`
adapts the callback sequence in `ReviewerViewModel.onEditedTags()` from
`AnkiDroid/src/main/java/com/ichi2/anki/ui/windows/reviewer/ReviewerViewModel.kt:665–679`,
pinned to AnkiDroid 2.25.3 commit
`d9bf072f814a0c37d30a694192593b31ff2df875`. It resolves the current card and
note once, reads the note's ordered tags once, skips the write and undoable
update for equal lists, otherwise writes `selectedTags.joinToString(" ")` and
then requests the undoable note update for that same note. Callback errors
propagate unchanged and stop subsequent work. Collection access, tag mutation,
undo storage, logging, and coroutine delivery remain host-owned. No direct
pinned `ReviewerViewModelTest` assertion was found; focused source-derived
cases are in `test/reviewer_edited_tags_operation_test.dart`. The source file
declares `GPL-3.0-or-later` and names no separate copyright holder. The Dart
adaptation and tests are Copyright © 2026 John Tsui under the same license;
root `COPYING` remains byte-identical.

## Flutter profile startup and persistent profile runtime

`apps/anki/lib/shared_profile_runtime.dart` supplies the shared startup and
profile repository used by `apps/anki/lib/main.dart` on Android, iOS, macOS,
Linux, Windows, and Web. It persists onboarding completion, ordered profile
IDs and names, and the active profile ID in one versioned JSON record through
the Flutter `shared_preferences` plugin. Invalid or unsupported persisted
records raise an error; they are not interpreted as a fresh installation.
The deterministic key-value fake and focused persistence cases are in
`apps/anki/test/shared_profile_runtime_test.dart`.

The behavior boundary follows AnkiDroid 2.25.3, pinned to commit
`d9bf072f814a0c37d30a694192593b31ff2df875`: `ProfileManager.kt` governs
creating and activating the default profile and unique profile IDs;
`ProfileName.kt` supplies validated display names;
`SetupStorage.kt`, `BackendSetup.kt`, and `StoragePolicy.kt` inform first-run
setup; and `StartupGuards.kt` informs the ordered profile-switch checks exposed
by `ProfileRepository`. Shared preferences is the cross-platform Flutter
storage choice and is not copied from AnkiDroid. Collection storage, backend
initialization, and profile-specific collection files remain outside this
runtime. The referenced AnkiDroid source files declare `GPL-3.0-or-later`; no
upstream assets or translated resource strings are copied. The Dart code and
tests are Copyright © 2026 John Tsui under `GPL-3.0-or-later`; root `COPYING`
remains unchanged. The shared_preferences plugin and its platform packages
are Copyright © 2013 The Flutter Authors and distributed under the BSD 3-Clause
License.

## Card Browser semantic row theme colors

`apps/anki/lib/card_browser_row_colors.dart` adapts the Card Browser color
resolution in AnkiDroid 2.25.3's
`AnkiDroid/src/main/java/com/ichi2/anki/browser/BrowserMultiColumnAdapter.kt`,
pinned to `d9bf072f814a0c37d30a694192593b31ff2df875`. `onBindViewHolder()`
first applies `focusedRowBackgroundColor` when the row is the focused pane row;
otherwise it maps the backend row color. Marked, suspended, and buried colors
come from theme attributes. Flag colors come from `Flag.browserColorRes`, with
the `values-night` resource variant in dark/black themes. Default and
unrecognized colors use the theme's `android:colorBackground`. A backend error
row uses that unrecognized/default background, shows the error, is unchecked,
and is struck through. Selection itself changes the checkbox only; it does not
replace the semantic row background. `setColor()` adds pressed and keyboard
focus feedback on top of the base background.

The shared Flutter resolver preserves these priorities and the exact pinned
light, dark, black, and e-ink resource values. Brightness selects light or dark
by default; a host can opt into black or e-ink through
`CardBrowserPaletteTheme`. Black and e-ink palettes are projections because the
Flutter app currently has no corresponding theme setting. The resolver accepts
a focused-row input, but this app has no pane-current row state to pass to it;
pane focus behavior remains available at the shared mapping boundary. The
renderer chooses black or white row text for semantic backgrounds to preserve
at least 4.5:1 contrast while leaving source backgrounds unchanged. Focused,
default, unknown, and error rows prefer the theme's on-surface text color when it
meets that contrast threshold against the resolved background; otherwise the
renderer chooses whichever of black or white has higher contrast.

The mapping has focused tests for every semantic value in light and dark modes,
black/e-ink projections, focused precedence, theme background fallback,
brightness changes, selection/error rendering, and text contrast. The current
Flutter renderer has no keyboard-pane focus state, so actual focused-pane
rendering cannot be exercised until that host state exists. Source hashes for
the adapter, `Flag.kt`, theme resources, and shared Material colors are recorded
in `apps/anki/ANKIDROID_SOURCE.sha256`. The Kotlin source declares
`GPL-3.0-or-later`; the resource values are adapted rather than copied as
Android resources. The Flutter mapping and tests are Copyright © 2026 John
Tsui under `GPL-3.0-or-later`. Root `COPYING` remains byte-identical.

## Card Browser preview launch and Previewer screen

The collection-backed Card Browser preview route in
`apps/anki/lib/collection_card_browser_controller.dart`,
`card_browser_preview.dart`, and `card_browser_preview_screen.dart` follows
AnkiDroid 2.25.3 at `d9bf072f814a0c37d30a694192593b31ff2df875`:
`CardBrowserViewModel.kt:1265–1282`, `CardBrowserFragment.kt:1595–1605`,
`PreviewerFragment.kt:70–183,205–255`, and `PreviewerViewModel.kt:32–63,93–104,134–202`.
The exact source and test hashes are in
`apps/anki/ANKIDROID_SOURCE.sha256`; the behavior mapping and limits are in
`ANKIDROID_UPSTREAM.md`. The referenced Kotlin sources declare
`GPL-3.0-or-later`; no Android code, resources, or strings are copied.

Static question and answer HTML is presented through `flutter_html` 3.0.0, a
Flutter-widget renderer published under MIT. Its dependency on the `html`
package is constrained to 0.15.5 because 0.15.7 removed the internal selector
API used by `flutter_html` 3.0.0. The app uses the renderer's Flutter widget
surface on Android, iOS, Web, Windows, macOS, and Linux; JavaScript and media
playback parity are not included. Root `COPYING` remains byte-identical.

## Shared cross-platform new-note editor (Unit39)

The shared add flow in `apps/anki/lib/note_editor_screen.dart`,
`card_browser_screen.dart`, and `collection_card_browser_controller.dart` is
source-derived from AnkiDroid 2.25.3 at `d9bf072f814a0c37d30a694192593b31ff2df875`.
`NoteEditorFragment.setupEditor()` classifies the caller and initializes add
mode (`NoteEditorFragment.kt:625–820`); note fields come from the selected
current notetype via `setNote(null, ...)` (`2143–2165`).
`libanki/Notetypes.current()` selects the current deck's `mid`, then `curModel`
or ID 1, and finally the first note type (`Notetypes.kt:152–162`). The spinner
list is alphabetically ordered (`NoteTypeSpinnerUtils.kt:12–39`), while the
initial selected position comes from the note itself
(`NoteEditorFragment.kt:2425–2429`).

Deck resolution preserves `EXTRA_DID` when it names a usable normal deck;
zero, missing, or filtered IDs fall through to `defaultsForAdding()` during
setup (`NoteEditorFragment.kt:754–778`). Without an explicit ID,
`setDid()` uses the current note type's remembered destination when
`ADDING_DEFAULTS_TO_CURRENT_DECK` is false, otherwise the selected current
deck, with filtered current decks falling back to Default
(`NoteEditorFragment.kt:2107–2135`; `Collection.kt:738–756`). The Card Browser
caller supplies current search terms and its persisted `lastDeckId`
(`CardBrowserFragment.kt:1881–1889`); `CardBrowserViewModel.setSelectedDeck()`
stores that ID independently of the collection current deck
(`CardBrowserViewModel.kt:401–414`). The Dart controller contract accepts an
explicit `selectedNewNoteDeckId`, but the current app does not yet connect an
equivalent persisted Card Browser deck repository. Its no-override path uses
the active collection's current deck and `addToCur`/remembered-deck settings;
this is documented as a host integration gap rather than exact last-deck
parity.

`saveNote()` copies field and tag edits, prevents overlapping add jobs, checks
the fields result and only then calls the collection add operation
(`NoteEditorFragment.kt:1259–1290`). `saveNoteWithProgress()` passes the
selected deck ID to `addNote()` and reports Core's generated-card count
(`1243–1253`). `onNoteAdded(count)` resets note data and only closes callers
that request close; the Card Browser caller stays in the editor for another
note (`1212–1241`). `NoteFieldsCheckResult.kt:50–79` maps NORMAL and DUPLICATE
to success, the empty/cloze states to their localized failures, and
UNRECOGNIZED to a failure with no message. The Dart flow reuses
`anki_backend_models.noteFieldsCheck()` and
`projectNoteFieldsCheckResult()`; it adds no duplicate prompt.

The collection host calls Unit38's atomic `addNoteToDeck()` once after
validation. The shared editor retains edits after validation/storage errors,
shows the returned generated-card count, and resets for the next note. When it
closes, Card Browser refreshes its active search while keeping row selection.
Focused widget and collection-controller tests cover setup, field/tag entry,
validation and duplicate handling, failed-save retention, single-flight add,
next-note reset, deck fallback, returned card count, and browser refresh.
Source hashes for the cited pinned AnkiDroid and libanki files are recorded in
`apps/anki/ANKIDROID_SOURCE.sha256`; no Android source, assets, or strings were
copied. Root `COPYING` remains byte-identical.

## Deck Picker Add Card route (Unit40)

The Deck Picker context-menu Add Card action now routes to the same shared
new-note editor and Unit38 collection operation used by Card Browser. In the
pinned source, `DeckPicker.onContextMenuOptionSelected(ADD_CARD)` calls
`DeckPickerViewModel.addNote(deckId, setAsCurrent = true)`; the view model
selects that deck in the collection before emitting
`NoteEditorDestination.AddNote(deckId)` (`DeckPicker.kt:1058–1065`,
`DeckPickerViewModel.kt:287–295`). The Flutter host performs the same
selection before building the editor port and retains the exact `Int64` deck
ID through the add route. On save, the editor remains open and resets for the
next note, matching `NoteEditorFragment.onNoteAdded()` for callers that do not
request close (`NoteEditorFragment.kt:1212–1241`). Returning to the Deck Picker
reloads the deck tree/counts. Other context actions remain host operations;
Root `COPYING` remains byte-identical and no Android source or resource was
copied.

## Deck Picker add-note shortcut (Unit41)

The cross-platform Deck Picker handles the pinned `A` key on key-up and opens
the shared new-note editor without an explicit deck override. This mirrors
`DeckPicker.onKeyUp(KEYCODE_A)`, which skips handling while the deck search
field has focus and calls `DeckPickerViewModel.addNote(deckId = null,
setAsCurrent = true)` (`DeckPicker.kt:1657–1669`). The collection-backed
editor port consequently uses the collection's current/default deck behavior,
including exact 64-bit IDs on Web. Root `COPYING` remains byte-identical; no
Android source or resource was copied.

## Deck Picker Browse Cards route (Unit42)

The context-menu Browse Cards action now carries the exact collection `Int64`
deck ID through selection and the host route callback, so Web does not narrow
IDs above JavaScript's safe integer range. This matches
`DeckPickerViewModel.browseCards(deckId)`, which selects that deck before
emitting `BrowserDestination.ToDeck(deckId)` (`DeckPicker.kt:1057–1061`,
`DeckPickerViewModel.kt:277–280`). The optional exact-ID adapter preserves the
existing repository fallback for non-collection hosts. Independently persisted
Browser `lastDeckId` remains a separate source behavior. Root `COPYING` remains
byte-identical; no Android source or resource was copied.
