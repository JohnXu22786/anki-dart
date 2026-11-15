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
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral reference: SearchHistory.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Card Browser search history persistence', () {
    test('loads with one source-default read and decodes the stored value', () {
      final calls = <String>[];
      final persistence = BrowserSearchHistoryPersistence(
        preferenceKey: 'search-history-key',
        getString: (key, defaultValue) {
          calls.add('get:$key:$defaultValue');
          return '[{"q":"query"}]';
        },
        putString: (key, value) => calls.add('put:$key:$value'),
      );

      expect(persistence.entries, [
        const BrowserSearchHistoryEntry(query: 'query'),
      ]);
      expect(calls, ['get:search-history-key:[]']);
    });

    test('null stored value decodes the source fallback as an empty list', () {
      final calls = <String>[];
      final persistence = BrowserSearchHistoryPersistence(
        preferenceKey: 'key',
        getString: (key, defaultValue) {
          calls.add('$key:$defaultValue');
          return null;
        },
        putString: (key, value) {},
      );

      expect(persistence.entries, isEmpty);
      expect(calls, ['key:[]']);
    });

    test('malformed stored JSON returns an empty list', () {
      final persistence = BrowserSearchHistoryPersistence(
        preferenceKey: 'key',
        getString: (key, defaultValue) => '[{"q":42}]',
        putString: (key, value) {},
      );

      expect(persistence.entries, isEmpty);
    });

    test('getter failures propagate unchanged without a second read', () {
      final failure = StateError('get failed');
      var getCalls = 0;
      final persistence = BrowserSearchHistoryPersistence(
        preferenceKey: 'key',
        getString: (key, defaultValue) {
          getCalls++;
          throw failure;
        },
        putString: (key, value) {},
      );

      expect(() => persistence.entries, throwsA(same(failure)));
      expect(getCalls, 1);
    });

    test('encodes the supplied list before one write with the exact JSON', () {
      final calls = <String>[];
      final persistence = BrowserSearchHistoryPersistence(
        preferenceKey: 'history',
        getString: (key, defaultValue) => null,
        putString: (key, value) => calls.add('put:$key:$value'),
      );
      const entries = [
        BrowserSearchHistoryEntry(query: 'first', tags: ['tag']),
        BrowserSearchHistoryEntry(query: 'second', deckIds: [7]),
      ];

      persistence.entries = entries;

      expect(calls, [
        'put:history:[{"q":"first","t":["tag"]},{"q":"second","did":[7]}]',
      ]);
    });

    test('encoding and host write failures propagate and stop later work', () {
      final writes = <String>[];
      final persistence = BrowserSearchHistoryPersistence(
        preferenceKey: 'key',
        getString: (key, defaultValue) => null,
        putString: (key, value) {
          writes.add(value);
          throw StateError('put failed');
        },
      );
      final writeFailure = expectLater(
        () => persistence.entries = const [
          BrowserSearchHistoryEntry(query: 'entry'),
        ],
        throwsA(isA<StateError>()),
      );

      expect(writes, ['[{"q":"entry"}]']);
      expect(writeFailure, completes);

      writes.clear();
      expect(
        () => persistence.entries = const [
          BrowserSearchHistoryEntry(query: 'invalid', flags: [99]),
        ],
        throwsArgumentError,
      );
      expect(writes, isEmpty);
    });
  });
}
