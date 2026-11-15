/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
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
 * Source-derived adapter cases for Collection.getReviewLogs(); see
 * ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('collectionGetReviewLogs', () {
    test('forwards the card ID once and returns the identical list', () {
      const cardId = 42;
      final entries = <Object>[Object()];
      var calls = 0;

      final result = collectionGetReviewLogs<Object>(cardId, (receivedId) {
        calls++;
        expect(receivedId, cardId);
        return entries;
      });

      expect(calls, 1);
      expect(identical(result, entries), isTrue);
    });

    test('propagates the identical callback exception', () {
      final failure = StateError('host review logs failed');

      expect(
        () => collectionGetReviewLogs<Object>(42, (_) => throw failure),
        throwsA(same(failure)),
      );
    });
  });
}
