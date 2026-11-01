# AnkiDroid upstream source record

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
