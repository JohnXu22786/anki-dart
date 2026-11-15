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
 * Source-derived from Collection.kt in AnkiDroid 2.25.3; see ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('collectionSyncStatus', () {
    test('forwards auth once and returns the exact backend result', () {
      final auth = Object();
      final result = Object();
      var calls = 0;

      final actual = collectionSyncStatus<Object, Object>(
        auth,
        syncStatus: (receivedAuth) {
          calls++;
          expect(receivedAuth, same(auth));
          return result;
        },
      );

      expect(calls, 1);
      expect(actual, same(result));
    });

    test('propagates backend failures unchanged', () {
      final failure = StateError('sync status failed');
      expect(
        () => collectionSyncStatus<Object, Object>(
          Object(),
          syncStatus: (_) => throw failure,
        ),
        throwsA(same(failure)),
      );
    });
  });

  group('collectionMediaSyncStatus', () {
    test(
      'preserves the source unused-auth behavior and returns the result',
      () {
        final auth = Object();
        final result = Object();
        var calls = 0;

        final actual = collectionMediaSyncStatus<Object, Object>(
          auth,
          mediaSyncStatus: () {
            calls++;
            return result;
          },
        );

        expect(calls, 1);
        expect(actual, same(result));
      },
    );

    test('propagates backend failures unchanged', () {
      final failure = StateError('media status failed');
      expect(
        () => collectionMediaSyncStatus<Object, Object>(
          Object(),
          mediaSyncStatus: () => throw failure,
        ),
        throwsA(same(failure)),
      );
    });
  });

  group('collectionGetPreferences', () {
    test('returns the exact backend Preferences result', () {
      final result = Object();
      var calls = 0;

      final actual = collectionGetPreferences<Object>(
        getPreferences: () {
          calls++;
          return result;
        },
      );

      expect(calls, 1);
      expect(actual, same(result));
    });

    test('propagates backend failures unchanged', () {
      final failure = StateError('get preferences failed');
      expect(
        () => collectionGetPreferences<Object>(
          getPreferences: () => throw failure,
        ),
        throwsA(same(failure)),
      );
    });
  });

  group('collectionSetPreferences', () {
    test('forwards the exact Preferences and returns OpChanges unchanged', () {
      final preferences = Object();
      final result = Object();
      var calls = 0;

      final actual = collectionSetPreferences<Object, Object>(
        preferences,
        setPreferences: (receivedPreferences) {
          calls++;
          expect(receivedPreferences, same(preferences));
          return result;
        },
      );

      expect(calls, 1);
      expect(actual, same(result));
    });

    test('propagates backend failures unchanged', () {
      final failure = StateError('set preferences failed');
      expect(
        () => collectionSetPreferences<Object, Object>(
          Object(),
          setPreferences: (_) => throw failure,
        ),
        throwsA(same(failure)),
      );
    });
  });
}
