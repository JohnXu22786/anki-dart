# Source and license notice

`web/sqlite3.wasm` is the `sqlite3.wasm` release asset from
[`sqlite3-3.9.1`](https://github.com/simolus3/sqlite3.dart/releases/tag/sqlite3-3.9.1),
matching the locked `sqlite3` Dart package version and SHA-256 digest reported
by that release. The asset URL is
<https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-3.9.1/sqlite3.wasm>.
It is distributed under MIT. The package is copyright © 2020 Simon Binder.
Its license is reproduced at
`LICENSES/sqlite3-MIT.txt`, and the asset and license checksums are in
`SOURCE.sha256`.

The application code and profile-scoped runtime are Copyright © 2026 John
Tsui and distributed under AGPL-3.0-or-later, matching the linked Anki
collection runtime. The complete license text is in `LICENSE`. This runtime
uses the existing `anki_collection_sqlite` package, whose Anki Core source mappings and notices
are documented in `../../packages/anki_collection_sqlite/NOTICE.md`.

The app collection lifecycle in `lib/startup_shell.dart` and
`lib/app_collection_callbacks.dart` follows AnkiDroid 2.25.3 startup and
collection-load behavior at
`AnkiDroid/src/main/java/com/ichi2/anki/deckpicker/DeckPickerViewModel.kt:537–566`
and `AnkiDroid/src/main/java/com/ichi2/anki/AnkiActivity.kt:394–430`, pinned
to `d9bf072f814a0c37d30a694192593b31ff2df875`. Collection open/create ordering,
schema checks, migration transaction, and first-create callbacks follow Anki
Core `rslib/src/storage/sqlite.rs:53–90,478–550` at
`e64c6b1aee3e8d668fb8bbe084beada8e070d985`, with the stock note-type sequence
from `rslib/src/notetype/stock.rs:21–49`. SHA-256 values are recorded in
`ANKIDROID_SOURCE.sha256`; the app supplies localized strings and invokes the
already-mapped schema/SQLite packages rather than copying upstream source.

The Card Browser note type, card template, and note sort-field projections in
`lib/collection_card_browser_controller.dart` follow Anki Core
`rslib/src/browser_table.rs`, `rslib/src/notetype/mod.rs`, and `rslib/src/text.rs` at
`e64c6b1aee3e8d668fb8bbe084beada8e070d985`, and AnkiDroid's column meanings in
`AnkiDroid/src/main/java/com/ichi2/anki/browser/CardBrowserColumn.kt` at
`d9bf072f814a0c37d30a694192593b31ff2df875`. These source-derived behaviors
and source SHA-256 values are recorded in `ANKIDROID_SOURCE.sha256`. The
shared Dart storage loader is part of the AGPL-3.0-or-later application; the
full license text remains in `LICENSE` and the repository root `COPYING`.

Sort-field text conversion reuses `anki_backend_models`' HTML field-text
helper, which includes the htmlescape 0.3.1 entity table. Its attribution,
license notice, and third-party source hashes are recorded in
`../../packages/anki_backend_models/NOTICE.md` and
`../../packages/anki_backend_models/THIRD_PARTY_SOURCE.sha256`.

Card Browser scheduling values and row metadata in
`lib/browser_row_values.dart` and `lib/collection_card_browser_controller.dart`
are independently implemented from Anki Core's `rslib/src/browser_table.rs`,
`rslib/src/scheduler/timespan.rs`, `rslib/src/scheduler/timing.rs`,
`rslib/src/card/mod.rs`, and `rslib/src/timestamp.rs` at
`e64c6b1aee3e8d668fb8bbe084beada8e070d985`, plus AnkiDroid's
`CardBrowserViewModel.kt`, `CardBrowserColumn.kt`, LibAnki `BrowserConfig.kt`,
and `BrowserMultiColumnAdapter.kt` at
`d9bf072f814a0c37d30a694192593b31ff2df875`. The adapter consumes row color but
ignores row font, per-cell RTL, and elision metadata. Core source is
AGPL-3.0-or-later; AnkiDroid source is GPL-3.0-or-later. No upstream code or
Android resource is copied. The app-level implementation and new English strings remain
AGPL-3.0-or-later; root `COPYING` is unchanged. Exact source hashes are in
`ANKIDROID_SOURCE.sha256`. App English timespan resources are sourced from
Core's English semantics; non-English catalogs are not part of this app yet.
