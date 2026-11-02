/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from Fsrs.kt in AnkiDroid 2.25.3; see ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('FsrsVersion', () {
    test('maps every supported library version and preserves its value', () {
      const expectedByLibraryVersion = {
        '0.6.4': 'FSRS 4.5',
        '1.4.3': 'FSRS 5',
        '2.0.3': 'FSRS 5',
        '4.1.1': 'FSRS 6',
        '5.1.0': 'FSRS 6',
        '5.2.0': 'FSRS 6',
        '6.3.0': 'FSRS 6',
        '6.6.2': 'FSRS 6',
      };

      for (final entry in expectedByLibraryVersion.entries) {
        final version = FsrsVersion(entry.key);

        expect(version.displayString, entry.value, reason: entry.key);
        expect(version.libraryVersion, entry.key, reason: entry.key);
      }
    });

    test('does not infer labels for unknown or near-match versions', () {
      for (final libraryVersion in ['', '0.6', '0.6.5', '6.0.0', '6.6.3']) {
        expect(
          FsrsVersion(libraryVersion).displayString,
          isNull,
          reason: libraryVersion,
        );
      }
    });
  });
}
