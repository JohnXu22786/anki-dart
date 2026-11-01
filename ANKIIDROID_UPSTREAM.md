# AnkiDroid upstream source record

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
operation order. The conversion truncates finite in-range values toward zero,
maps NaN to zero, and saturates infinities and out-of-range values to signed
64-bit Long bounds. The subtraction then uses binary64 arithmetic, including
the conversion of the saturated Long back to double. The focused tests exercise
signed fractional inputs, negative zero, NaN, infinities, both Long bounds, and
remainder calculation beyond those bounds. No direct test for this upstream
extension was found in the pinned checkout. The upstream source declares
`GPL-3.0-or-later` and Copyright © 2026 Shaan Narendran
<shaannaren06@gmail.com>; the Dart adaptation and test are Copyright © 2026
John Tsui and marked `GPL-3.0-or-later`. Root `COPYING` remains byte-identical.

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
returns the fallback for null or empty Strings, preserves nonempty String
values, and invokes the callback lazily exactly once only when needed;
exceptions thrown by it propagate. Kotlin accepts every `CharSequence` subtype,
while this Dart API accepts only `String` because the package exposes no
corresponding type hierarchy. It makes no claim of preserving identity for
other `CharSequence` implementations. The pinned source declares
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

## JsonWriter serialization

`writeJsonObject()` in `lib/src/json_writer.dart` and its focused cases in
`test/json_writer_test.dart` adapt `JsonWriter.writeObject()` and its private
recursive `writeValue()` from
`AnkiDroid/src/main/java/com/ichi2/anki/utils/ext/JsonWriter.kt`, pinned to
AnkiDroid 2.25.3 commit `d9bf072f814a0c37d30a694192593b31ff2df875`. The
projection calls `beginObject`, then each host object key's `name` and value in
the key iterator's order, and finally `endObject`. Nested objects and arrays
stream recursively; arrays snapshot the host length once after `beginArray`, then use `opt(index)`.
Null and the host JSON-null sentinel call `nullValue`; Boolean and Number values
use their matching callbacks; other values are converted with `toString()` and
written as strings. Sink and host callback failures propagate unchanged and stop
subsequent operations. No full JSON document is built. The host retains Android
`JsonWriter` escaping, encoding and chunking, `JSONObject`/`JSONArray` key, get,
and opt behavior, and `File.writeJson()` UTF-8 buffered writer creation and close
ownership. The pinned direct
`AnkiDroid/src/test/java/com/ichi2/anki/utils/ext/JsonWriterTest.kt` covers
streaming serialization, bounded chunks, and write failure propagation. The
Kotlin source and direct test declare `GPL-3.0-or-later` and have no separate
copyright line; the Dart adaptation and tests are Copyright © 2026 John Tsui
under the same license. Root `COPYING` remains byte-identical.
