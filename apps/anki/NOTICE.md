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
