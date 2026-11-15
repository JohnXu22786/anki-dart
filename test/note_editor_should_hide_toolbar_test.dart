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
 * Source-derived from NoteEditorFragment.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('noteEditorShouldHideToolbar', () {
    for (final storedValue in [true, false]) {
      test('reads the exact preference once and returns ${!storedValue}', () {
        final events = <String>[];
        final preferences = Object();
        var sharedPrefsCalls = 0;
        var booleanReadCalls = 0;

        final actual = noteEditorShouldHideToolbar<Object>(
          sharedPrefs: () {
            events.add('sharedPrefs');
            sharedPrefsCalls++;
            return preferences;
          },
          getBoolean: (actualPreferences, key, defaultValue) {
            events.add('getBoolean');
            booleanReadCalls++;
            expect(identical(actualPreferences, preferences), isTrue);
            expect(key, 'noteEditorShowToolbar');
            expect(defaultValue, isTrue);
            return storedValue;
          },
        );

        expect(events, ['sharedPrefs', 'getBoolean']);
        expect(sharedPrefsCalls, 1);
        expect(booleanReadCalls, 1);
        expect(actual, !storedValue);
      });
    }

    test('shared preferences lookup failure skips the boolean read', () {
      final failure = StateError('shared preferences failed');
      var booleanReadCalls = 0;

      expect(
        () => noteEditorShouldHideToolbar<Object>(
          sharedPrefs: () => throw failure,
          getBoolean: (_, _, _) {
            booleanReadCalls++;
            return false;
          },
        ),
        throwsA(same(failure)),
      );
      expect(booleanReadCalls, 0);
    });

    test('boolean read failure propagates unchanged', () {
      final failure = StateError('boolean read failed');
      var sharedPrefsCalls = 0;
      var booleanReadCalls = 0;

      expect(
        () => noteEditorShouldHideToolbar<Object>(
          sharedPrefs: () {
            sharedPrefsCalls++;
            return Object();
          },
          getBoolean: (_, _, _) {
            booleanReadCalls++;
            throw failure;
          },
        ),
        throwsA(same(failure)),
      );
      expect(sharedPrefsCalls, 1);
      expect(booleanReadCalls, 1);
    });
  });
}
