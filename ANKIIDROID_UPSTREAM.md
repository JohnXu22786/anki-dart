# AnkiDroid upstream source record

This repository is a partial, modified Dart port of AnkiDroid 2.25.3. The
upstream source baseline is commit
`d9bf072f814a0c37d30a694192593b31ff2df875` from
[AnkiDroid](https://github.com/ankidroid/Anki-Android). This file records the
source scope for the add-on manifest projection implemented in this change;
other mapped units are summarized in the repository README and NOTICE.

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
