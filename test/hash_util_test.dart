/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
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
 * Source-derived from HashUtil.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('HashUtil capacity adapters', () {
    test(
      'uses the source capacity formula for ordinary, zero, and negative sizes',
      () {
        final capacities = <int>[];
        Object createSet(int capacity) {
          capacities.add(capacity);
          return Object();
        }

        for (final (size, expected) in [
          (0, 16),
          (-1, 16),
          (11, 16),
          (12, 17),
          (24, 33),
        ]) {
          hashSetInit(size, createSet: createSet);
          expect(capacities.last, expected);
          hashMapInit(size, createMap: createSet);
          expect(capacities.last, expected);
        }
        expect(capacities, hasLength(10));
      },
    );

    test(
      'preserves Float32 rounding and saturated Int32 conversion with overflow',
      () {
        final capacities = <int>[];
        Object record(int capacity) {
          capacities.add(capacity);
          return Object();
        }

        hashSetInit(16777217, createSet: record);
        hashSetInit(1610612735, createSet: record);
        hashMapInit(2147483647, createMap: record);
        hashMapInit(-2147483648, createMap: record);

        expect(capacities, [22369623, 16, 16, 16]);
      },
    );

    test('calls the host constructor once and returns its exact result', () {
      final setResult = Object();
      final mapResult = Object();
      var setCalls = 0;
      var mapCalls = 0;

      expect(
        hashSetInit(
          12,
          createSet: (capacity) {
            setCalls++;
            expect(capacity, 17);
            return setResult;
          },
        ),
        same(setResult),
      );
      expect(
        hashMapInit(
          12,
          createMap: (capacity) {
            mapCalls++;
            expect(capacity, 17);
            return mapResult;
          },
        ),
        same(mapResult),
      );
      expect(setCalls, 1);
      expect(mapCalls, 1);
    });

    test('propagates host constructor failures unchanged', () {
      final setFailure = StateError('set constructor failed');
      final mapFailure = StateError('map constructor failed');

      expect(
        () => hashSetInit(1, createSet: (_) => throw setFailure),
        throwsA(same(setFailure)),
      );
      expect(
        () => hashMapInit(1, createMap: (_) => throw mapFailure),
        throwsA(same(mapFailure)),
      );
    });
  });
}
