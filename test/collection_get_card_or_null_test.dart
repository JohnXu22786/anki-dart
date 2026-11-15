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
 * Source-derived from Collection.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('collectionGetCardOrNull', () {
    test('forwards the exact ID object and calls getCard once', () {
      final id = Object();
      var calls = 0;
      Object? receivedId;

      collectionGetCardOrNull(id, (received) {
        calls++;
        receivedId = received;
        return null;
      });

      expect(identical(receivedId, id), isTrue);
      expect(calls, 1);
    });

    test('returns the identical card object on success', () {
      final id = 42;
      final card = Object();

      final result = collectionGetCardOrNull(id, (receivedId) {
        expect(receivedId, id);
        return card;
      });

      expect(identical(result, card), isTrue);
    });

    test('returns null when getCard throws an Exception', () {
      final failure = Exception('missing card');

      expect(collectionGetCardOrNull(42, (_) => throw failure), isNull);
    });

    test('returns null when getCard throws an Error', () {
      final failure = StateError('backend failure');

      expect(collectionGetCardOrNull(42, (_) => throw failure), isNull);
    });
  });
}
