<!--
Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
SPDX-License-Identifier: GPL-3.0-or-later
-->

# Anki Flutter app

The shared Flutter app provides first-run storage onboarding, an active-profile
home, profile selection, creation, and renaming, plus the responsive Deck
Picker, filtered-deck options UI, and Card Browser on Android, iOS, web,
Windows, macOS, and Linux. The root `anki_dart` package remains headless pure
Dart; `apps/anki` depends on it through a local path dependency.

`AppServices` injects storage/startup, profile, and deck picker repository
boundaries. The Deck Picker renders host-projected deck trees, counts, and
filtered-deck options; it delegates selection, study, deck operations, and
filtered-deck building to the injected `DeckPickerRepository`. The default
repository shows a localized unavailable state until a platform/backend
adapter is connected.
The shared Dart profile manager chooses the default profile, generates unique
IDs, and runs ordered profile-switch safety checks. The default app services
persist onboarding completion, ordered profile records, and active-profile
selection through `shared_preferences` on Android, iOS, macOS, Linux, Windows,
and Web. Corrupt state and storage failures are surfaced instead of being
treated as a fresh install. Collection storage and backend startup remain
outside this profile-runtime unit; the Deck Picker continues to use its
injected repository boundary.

The profile flow follows AnkiDroid 2.25.3 at pinned commit
`d9bf072f814a0c37d30a694192593b31ff2df875`. See the root
[`ANKIDROID_UPSTREAM.md`](../../ANKIDROID_UPSTREAM.md) and
[`NOTICE.md`](../../NOTICE.md) for source and license provenance.

`AppServices.collections` owns one profile-scoped
`CollectionSqliteStorage` connection. Native platforms use the app support
directory and bundled SQLite; Web uses the `sqlite3.wasm` asset and an
IndexedDB-backed virtual file system. The stable location is derived from the
profile ID, not its editable display name. Closing or switching profiles
flushes and closes the prior connection without deleting its database. The
Web IndexedDB driver is experimental and does not guarantee crash durability.
This runtime establishes only the storage and connection boundary; collection
schema open/create callbacks and a deck repository are owned by the following
unit, so this app is not yet ready for end-to-end collection use.

The Web SQLite binary is the `sqlite3.wasm` release artifact matching the
locked `sqlite3` 3.9.1 package. Its SHA-256 and the bundled MIT license copy
are recorded in `SOURCE.sha256`; license text is in `LICENSES/sqlite3-MIT.txt`.

## Development

Use Flutter **3.47.9** with its bundled Dart **3.13.7**. From the repository
root:

```sh
cd apps/anki
flutter doctor -v
flutter pub get
flutter analyze
flutter test
```

To run the shell, use `flutter run -d <device>` with a device reported by
`flutter devices`. For example, `flutter run -d chrome` runs the Flutter shell
on web; it does not make the existing root Dart package's platform-dependent
helpers web-compatible.

Build commands are `flutter build apk --debug`, `flutter build web`,
`flutter build linux --debug`, `flutter build windows --debug`,
`flutter build macos --debug`, and `flutter build ios --no-codesign`.

Platform builds need the matching host tooling: Android SDK and JDK for
Android, Xcode on macOS for iOS and macOS, GTK 3 development libraries plus
Clang/CMake/Ninja for Linux, and Visual Studio with the Desktop development
with C++ workload for Windows. GitHub Actions uses matching hosted runners;
Linux installs its GTK and build dependencies in the workflow.
