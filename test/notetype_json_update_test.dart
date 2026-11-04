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
 * SPDX-License-Identifier: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from NotetypeJson.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('NotetypeJsonUpdate', () {
    test('enumerates once and overwrites in host order with source values', () {
      final source = Object();
      final destination = Object();
      final nestedValue = <String, Object>{'nested': Object()};
      final sourceValues = <String, Object?>{
        'second': nestedValue,
        'first': 'new first',
      };
      final destinationValues = <String, Object?>{
        'first': 'old first',
        'second': 'old second',
      };
      final events = <String>[];
      var keysCalls = 0;
      final update = NotetypeJsonUpdate<Object, Object?>(
        sourceJsonObject: source,
        destinationJsonObject: destination,
        keys: (actualSource) {
          expect(actualSource, same(source));
          keysCalls++;
          events.add('keys');
          return ['second', 'first'];
        },
        get: (actualSource, key) {
          expect(actualSource, same(source));
          events.add('get:$key');
          return sourceValues[key];
        },
        put: (actualDestination, key, value) {
          expect(actualDestination, same(destination));
          events.add('put:$key');
          destinationValues[key] = value;
        },
      );

      update.update();

      expect(keysCalls, 1);
      expect(events, [
        'keys',
        'get:second',
        'put:second',
        'get:first',
        'put:first',
      ]);
      expect(destinationValues['first'], 'new first');
      expect(destinationValues['second'], same(nestedValue));
    });

    test('key iteration failure stops later reads and writes unchanged', () {
      final source = Object();
      final destination = Object();
      final failure = StateError('key iteration failed');
      final events = <String>[];
      var keysCalls = 0;
      final update = NotetypeJsonUpdate<Object, Object?>(
        sourceJsonObject: source,
        destinationJsonObject: destination,
        keys: (_) {
          keysCalls++;
          return _keysThenThrow('first', failure);
        },
        get: (_, key) {
          events.add('get:$key');
          return 'value';
        },
        put: (_, key, _) => events.add('put:$key'),
      );

      expect(update.update, throwsA(same(failure)));

      expect(keysCalls, 1);
      expect(events, ['get:first', 'put:first']);
    });

    test('get failure stops its put and all later keys unchanged', () {
      final source = Object();
      final destination = Object();
      final failure = StateError('get failed');
      final events = <String>[];
      final update = NotetypeJsonUpdate<Object, Object?>(
        sourceJsonObject: source,
        destinationJsonObject: destination,
        keys: (_) => ['first', 'broken', 'later'],
        get: (_, key) {
          events.add('get:$key');
          if (key == 'broken') throw failure;
          return key;
        },
        put: (_, key, _) => events.add('put:$key'),
      );

      expect(update.update, throwsA(same(failure)));

      expect(events, ['get:first', 'put:first', 'get:broken']);
    });

    test('put failure stops all later key reads unchanged', () {
      final source = Object();
      final destination = Object();
      final failure = StateError('put failed');
      final events = <String>[];
      final update = NotetypeJsonUpdate<Object, Object?>(
        sourceJsonObject: source,
        destinationJsonObject: destination,
        keys: (_) => ['first', 'broken', 'later'],
        get: (_, key) {
          events.add('get:$key');
          return key;
        },
        put: (_, key, _) {
          events.add('put:$key');
          if (key == 'broken') throw failure;
        },
      );

      expect(update.update, throwsA(same(failure)));

      expect(events, ['get:first', 'put:first', 'get:broken', 'put:broken']);
    });
  });
}

Iterable<String> _keysThenThrow(String key, Object failure) sync* {
  yield key;
  Error.throwWithStackTrace(failure, StackTrace.current);
}
