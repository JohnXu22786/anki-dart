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
 * Source-derived Note card query adapter tests; see ANKIIDROID_UPSTREAM.md.
 */

import 'dart:collection';

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('LibAnki Note card IDs', () {
    test('forwards the note ID once and returns the exact list', () {
      final ids = <int>[3, 8];
      final arguments = <int>[];

      final result = libankiNoteCardIds(
        noteId: 42,
        cardIdsOfNote: ({required nid}) {
          arguments.add(nid);
          return ids;
        },
      );

      expect(arguments, [42]);
      expect(result, same(ids));
    });

    test('propagates card ID lookup failures unchanged', () {
      final failure = StateError('card IDs failed');

      expect(
        () => libankiNoteCardIds(
          noteId: 42,
          cardIdsOfNote: ({required nid}) => throw failure,
        ),
        throwsA(same(failure)),
      );
    });
  });

  group('LibAnki Note.numberOfCards', () {
    test('delegates once to card IDs and returns their size', () {
      final calls = <String>[];

      final result = libankiNoteNumberOfCards(
        noteId: 42,
        cardIdsOfNote: ({required nid}) {
          expect(nid, 42);
          calls.add('cardIds');
          return _ObservedCardIds([3, 8, 11], calls);
        },
      );

      expect(calls, ['cardIds', 'size']);
      expect(result, 3);
    });

    test('propagates card ID lookup failures before reading a size', () {
      final failure = StateError('card IDs failed');

      expect(
        () => libankiNoteNumberOfCards(
          noteId: 42,
          cardIdsOfNote: ({required nid}) => throw failure,
        ),
        throwsA(same(failure)),
      );
    });
  });

  group('LibAnki Note.cards', () {
    test(
      'eagerly gets cards in ID order and returns exact objects in order',
      () {
        final ids = <int>[9, 4, 12];
        final cards = <int, Object>{9: Object(), 4: Object(), 12: Object()};
        final calls = <String>[];

        final result = libankiNoteCards<Object>(
          noteId: 42,
          cardIdsOfNote: ({required nid}) {
            calls.add('ids:$nid');
            return ids;
          },
          getCard: (id) {
            calls.add('card:$id');
            return cards[id]!;
          },
        );

        expect(calls, ['ids:42', 'card:9', 'card:4', 'card:12']);
        expect(result, hasLength(3));
        expect(result[0], same(cards[9]));
        expect(result[1], same(cards[4]));
        expect(result[2], same(cards[12]));
      },
    );

    test('stops at and propagates the first card lookup failure', () {
      final failure = StateError('card 4 failed');
      final calls = <int>[];

      expect(
        () => libankiNoteCards<Object>(
          noteId: 42,
          cardIdsOfNote: ({required nid}) => [9, 4, 12],
          getCard: (id) {
            calls.add(id);
            if (id == 4) throw failure;
            return Object();
          },
        ),
        throwsA(same(failure)),
      );
      expect(calls, [9, 4]);
    });

    test('propagates card ID lookup failures without looking up cards', () {
      final failure = StateError('card IDs failed');
      var cardCalls = 0;

      expect(
        () => libankiNoteCards<Object>(
          noteId: 42,
          cardIdsOfNote: ({required nid}) => throw failure,
          getCard: (_) {
            cardCalls++;
            return Object();
          },
        ),
        throwsA(same(failure)),
      );
      expect(cardCalls, 0);
    });
  });

  group('LibAnki Note.firstCard', () {
    test('runs the exact query once and passes its scalar to card lookup', () {
      final card = Object();
      final calls = <String>[];

      final result = libankiNoteFirstCard<Object>(
        noteId: 42,
        queryLongScalar: (query, argument) {
          calls.add('query:$query:$argument');
          return 928;
        },
        getCard: (id) {
          calls.add('card:$id');
          return card;
        },
      );

      expect(calls, [
        'query:SELECT id FROM cards WHERE nid = ? ORDER BY ord LIMIT 1:42',
        'card:928',
      ]);
      expect(result, same(card));
    });

    test('propagates query and card lookup failures unchanged', () {
      final queryFailure = StateError('query failed');
      var cardCalls = 0;

      expect(
        () => libankiNoteFirstCard<Object>(
          noteId: 42,
          queryLongScalar: (_, _) => throw queryFailure,
          getCard: (_) {
            cardCalls++;
            return Object();
          },
        ),
        throwsA(same(queryFailure)),
      );
      expect(cardCalls, 0);

      final cardFailure = StateError('card lookup failed');
      expect(
        () => libankiNoteFirstCard<Object>(
          noteId: 42,
          queryLongScalar: (_, _) => 928,
          getCard: (_) => throw cardFailure,
        ),
        throwsA(same(cardFailure)),
      );
    });
  });
}

final class _ObservedCardIds extends ListBase<int> {
  _ObservedCardIds(this.values, this.calls);

  final List<int> values;
  final List<String> calls;

  @override
  int get length {
    calls.add('size');
    return values.length;
  }

  @override
  set length(int value) => throw UnsupportedError('read-only test list');

  @override
  int operator [](int index) => values[index];

  @override
  void operator []=(int index, int value) => values[index] = value;
}
