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
 * Source-derived from LinearLayoutManager.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('visibleItemPositions', () {
    test('queries first then last exactly once', () {
      final events = <String>[];
      var firstCalls = 0;
      var lastCalls = 0;

      final positions = visibleItemPositions(
        findFirstVisibleItemPosition: () {
          events.add('first');
          firstCalls++;
          return 3;
        },
        findLastVisibleItemPosition: () {
          events.add('last');
          lastCalls++;
          return 6;
        },
      );

      expect(events, ['first', 'last']);
      expect(firstCalls, 1);
      expect(lastCalls, 1);
      expect(positions.first, 3);
      expect(positions.last, 6);
    });

    test('first NO_POSITION returns an empty range', () {
      final events = <String>[];
      final positions = visibleItemPositions(
        findFirstVisibleItemPosition: () {
          events.add('first');
          return -1;
        },
        findLastVisibleItemPosition: () {
          events.add('last');
          return 6;
        },
      );

      expect(events, ['first', 'last']);
      expect(positions.isEmpty, isTrue);
      expect(positions.contains(6), isFalse);
      expect(
        positionIsVisible(
          6,
          findFirstVisibleItemPosition: () => -1,
          findLastVisibleItemPosition: () => 6,
        ),
        isFalse,
      );
    });

    test('last NO_POSITION returns an empty range', () {
      final events = <String>[];
      final positions = visibleItemPositions(
        findFirstVisibleItemPosition: () {
          events.add('first');
          return 3;
        },
        findLastVisibleItemPosition: () {
          events.add('last');
          return -1;
        },
      );

      expect(events, ['first', 'last']);
      expect(positions.isEmpty, isTrue);
      expect(positions.contains(3), isFalse);
      expect(
        positionIsVisible(
          3,
          findFirstVisibleItemPosition: () => 3,
          findLastVisibleItemPosition: () => -1,
        ),
        isFalse,
      );
    });

    test('range includes its first, last, and interior positions', () {
      final positions = visibleItemPositions(
        findFirstVisibleItemPosition: () => 3,
        findLastVisibleItemPosition: () => 6,
      );

      expect(positions.contains(3), isTrue);
      expect(positions.contains(4), isTrue);
      expect(positions.contains(6), isTrue);
      expect(positions.contains(2), isFalse);
      expect(positions.contains(7), isFalse);
      expect(
        positionIsVisible(
          6,
          findFirstVisibleItemPosition: () => 3,
          findLastVisibleItemPosition: () => 6,
        ),
        isTrue,
      );
    });

    test('reversed bounds are empty and contain no positions', () {
      final positions = visibleItemPositions(
        findFirstVisibleItemPosition: () => 6,
        findLastVisibleItemPosition: () => 3,
      );

      expect(positions.isEmpty, isTrue);
      expect(positions.contains(3), isFalse);
      expect(positions.contains(6), isFalse);
      expect(
        positionIsVisible(
          4,
          findFirstVisibleItemPosition: () => 6,
          findLastVisibleItemPosition: () => 3,
        ),
        isFalse,
      );
    });
  });
}
