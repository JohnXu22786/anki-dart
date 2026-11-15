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
 * Source-derived adapter cases for Collection.cardStatsData(cardId); see
 * ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('collectionCardStatsData', () {
    test('forwards the exact card ID once and returns the host response', () {
      final cardId = Object();
      final response = Object();
      var calls = 0;
      Object? actualCardId;

      final actual = collectionCardStatsData<Object, Object>(
        cardId: cardId,
        cardStats: (value) {
          calls++;
          actualCardId = value;
          return response;
        },
      );

      expect(calls, 1);
      expect(actualCardId, same(cardId));
      expect(actual, same(response));
    });

    test('propagates the host callback failure unchanged', () {
      final failure = StateError('backend card stats failed');
      var calls = 0;

      expect(
        () => collectionCardStatsData<Object, Object>(
          cardId: Object(),
          cardStats: (_) {
            calls++;
            throw failure;
          },
        ),
        throwsA(same(failure)),
      );
      expect(calls, 1);
    });
  });
}
