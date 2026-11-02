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
 * Source-derived from Deck.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('decksUpdate', () {
    test('looks up once, mutates then saves the identical object', () {
      final deck = Object();
      final events = <String>[];
      var lookupCount = 0;

      decksUpdate<int, Object>(
        deckId: 42,
        getLegacy: (id) {
          events.add('lookup:$id');
          lookupCount++;
          return deck;
        },
        block: (resolved) {
          events.add('block');
          expect(identical(resolved, deck), isTrue);
        },
        save: (resolved) {
          events.add('save');
          expect(identical(resolved, deck), isTrue);
        },
      );

      expect(lookupCount, 1);
      expect(events, ['lookup:42', 'block', 'save']);
    });

    test('null lookup throws TypeError and skips block and save', () {
      final events = <String>[];

      expect(
        () => decksUpdate<int, Object>(
          deckId: 42,
          getLegacy: (id) {
            events.add('lookup');
            return null;
          },
          block: (_) => events.add('block'),
          save: (_) => events.add('save'),
        ),
        throwsA(isA<TypeError>()),
      );

      expect(events, ['lookup']);
    });

    test('block failure propagates and prevents save without rollback', () {
      final deck = Object();
      final failure = StateError('mutation failed');
      final events = <String>[];

      expect(
        () => decksUpdate<int, Object>(
          deckId: 42,
          getLegacy: (_) {
            events.add('lookup');
            return deck;
          },
          block: (resolved) {
            events.add('block');
            expect(identical(resolved, deck), isTrue);
            throw failure;
          },
          save: (_) => events.add('save'),
        ),
        throwsA(same(failure)),
      );

      expect(events, ['lookup', 'block']);
    });

    test('save failure propagates after block and save are called once', () {
      final deck = Object();
      final failure = StateError('save failed');
      final events = <String>[];

      expect(
        () => decksUpdate<int, Object>(
          deckId: 42,
          getLegacy: (_) {
            events.add('lookup');
            return deck;
          },
          block: (resolved) {
            events.add('block');
            expect(identical(resolved, deck), isTrue);
          },
          save: (resolved) {
            events.add('save');
            expect(identical(resolved, deck), isTrue);
            throw failure;
          },
        ),
        throwsA(same(failure)),
      );

      expect(events, ['lookup', 'block', 'save']);
    });
  });
}
