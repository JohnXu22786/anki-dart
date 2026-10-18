# anki-dart

This repository is an in-progress Dart port of AnkiDroid. Its source baseline
is AnkiDroid **2.25.3** (`v2.25.3`); the exact commit and the files compared so
far are recorded in [ANKIDROID_UPSTREAM.md](ANKIDROID_UPSTREAM.md).

## Current port scope

The first port slice is the deck picker's search and visible-row behavior:

- token and deck-path matching, including partial `:` / `::` searches;
- flattening a deck tree into visible rows, including ancestor paths, collapsed
  decks, counts, and selection state.

The implementation lives in `lib/` as a Dart library. This is not yet a complete
AnkiDroid replacement: the Android screens and lifecycle, collection storage,
Anki backend, scheduling, sync, import/export, and other app features remain to
be ported. The source project has thousands of files, so this repository does
not claim full feature parity.

The port preserves the source behavior for the covered slice, including its
search and collapse quirks. It does not intentionally correct upstream bugs.
See the tests for the specific behavior checks and the upstream mapping for the
corresponding source files.

## Use and verify

This package currently contains library code, not a runnable app. With Dart
3.3 or newer installed:

```sh
dart pub get
dart test
```

## License and attribution

The adapted deck-picker code is derived from AnkiDroid and is distributed under
**GNU GPL version 3 or, at your option, any later version** (`GPL-3.0-or-later`).
The source repository's root `COPYING` is the GNU GPL version 3 text; the
matching SPDX license text is included at
[`LICENSES/GPL-3.0-or-later.txt`](LICENSES/GPL-3.0-or-later.txt). Copyright and
SPDX notices remain in each adapted Dart source file. See [NOTICE.md](NOTICE.md)
for source-file attribution.

AnkiDroid's repository also identifies separately licensed components,
including the AnkiDroid API under LGPL-3.0 and parts of the Anki backend under
AGPL-3.0. Those components are not part of this initial Dart slice. If they are
ported later, their original file or component license and notices must be
retained; this repository does not relicense them under the deck-picker license.

This is an independent project and is not endorsed by or affiliated with the
AnkiDroid or Anki projects. The names are used only to identify the source and
compatibility target.
