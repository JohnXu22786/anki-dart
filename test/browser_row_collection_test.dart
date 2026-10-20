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
 */

import 'dart:async';

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('BrowserRowId', () {
    test('has Long-like value identity and selects the mode-specific ID', () {
      const cardId = BrowserRowId(37);
      expect(cardId, const BrowserRowId(37));
      expect(cardId.hashCode, const BrowserRowId(37).hashCode);
      expect(cardId.toString(), '37');
      expect(
        BrowserRowId.fromCard(
          cardId: 37,
          noteId: 83,
          mode: BrowserColumnMode.cards,
        ),
        cardId,
      );
      expect(
        BrowserRowId.fromCard(
          cardId: 37,
          noteId: 83,
          mode: BrowserColumnMode.notes,
        ),
        const BrowserRowId(83),
      );
    });

    test('toCardId uses the card directly or the note’s first card', () async {
      var lookups = 0;
      FutureOr<List<int>> lookup(int noteId) {
        lookups++;
        expect(noteId, 83);
        return [401, 402];
      }

      const id = BrowserRowId(83);
      expect(
        await id.toCardId(BrowserColumnMode.cards, cardIdsOfNote: lookup),
        83,
      );
      expect(lookups, 0);
      expect(
        await id.toCardId(BrowserColumnMode.notes, cardIdsOfNote: lookup),
        401,
      );
      expect(lookups, 1);
      expect(
        await id.toCardId(
          BrowserColumnMode.notes,
          cardIdsOfNote: (_) => <int>[],
        ),
        isNull,
      );
    });
  });

  group('BrowserRowCollection', () {
    test('replaceWith and reset mutate the supplied list and retain aliasing',
        () {
      final backing = [const BrowserRowId(10)];
      final rows = BrowserRowCollection(BrowserColumnMode.cards, backing);

      rows.replaceWith(BrowserColumnMode.notes, [
        const BrowserRowId(20),
        const BrowserRowId(30),
      ]);
      expect(rows.mode, BrowserColumnMode.notes);
      expect(backing, [const BrowserRowId(20), const BrowserRowId(30)]);
      expect(rows, [const BrowserRowId(20), const BrowserRowId(30)]);

      backing.add(const BrowserRowId(40));
      expect(rows.last, const BrowserRowId(40));

      rows.reset();
      expect(rows.mode, BrowserColumnMode.notes);
      expect(backing, isEmpty);
    });

    test('replaceWith preserves source behavior when given its own list', () {
      final rows = BrowserRowCollection(
        BrowserColumnMode.cards,
        [const BrowserRowId(10)],
      );

      rows.replaceWith(BrowserColumnMode.notes, rows);

      expect(rows.mode, BrowserColumnMode.notes);
      expect(rows, isEmpty);
    });

    test('queryNoteIds returns note rows or delegates card rows', () async {
      final notes = BrowserRowCollection(BrowserColumnMode.notes, [
        const BrowserRowId(7),
        const BrowserRowId(8),
      ]);
      expect(await notes.queryNoteIds(), [7, 8]);

      final cards = BrowserRowCollection(BrowserColumnMode.cards, [
        const BrowserRowId(70),
        const BrowserRowId(80),
      ]);
      List<int>? received;
      final noteIds = await cards.queryNoteIds(
        notesOfCards: (cardIds) {
          received = cardIds;
          return [7, 8, 7];
        },
      );
      expect(received, [70, 80]);
      expect(noteIds, [7, 8, 7]);
    });

    test(
        'queryCardIds expands notes sequentially and preserves order/duplicates',
        () async {
      final rows = BrowserRowCollection(BrowserColumnMode.notes, [
        const BrowserRowId(10),
        const BrowserRowId(20),
        const BrowserRowId(10),
      ]);
      final calls = <String>[];

      final cardIds = await rows.queryCardIds(cardIdsOfNote: (noteId) async {
        calls.add('start $noteId');
        await Future<void>.delayed(Duration.zero);
        calls.add('end $noteId');
        return noteId == 10 ? [101, 102] : [201, 101];
      });

      expect(calls, [
        'start 10',
        'end 10',
        'start 20',
        'end 20',
        'start 10',
        'end 10',
      ]);
      expect(cardIds, [101, 102, 201, 101, 101, 102]);

      final cards = BrowserRowCollection(BrowserColumnMode.cards, [
        const BrowserRowId(101),
        const BrowserRowId(102),
      ]);
      expect(await cards.queryCardIds(), [101, 102]);
    });

    test('queryOneCardIdPerRow picks the first note card and fails if empty',
        () async {
      final rows = BrowserRowCollection(BrowserColumnMode.notes, [
        const BrowserRowId(10),
        const BrowserRowId(20),
      ]);
      expect(
        await rows.queryOneCardIdPerRow(
          cardIdsOfNote: (noteId) => noteId == 10 ? [101, 102] : [201],
        ),
        [101, 201],
      );
      await expectLater(
        rows.queryOneCardIdPerRow(cardIdsOfNote: (_) => <int>[]),
        throwsStateError,
      );

      final cards = BrowserRowCollection(BrowserColumnMode.cards, [
        const BrowserRowId(101),
      ]);
      expect(await cards.queryOneCardIdPerRow(), [101]);
    });

    test('queryCardIdsAt selects one card row or expands one note row',
        () async {
      final cards = BrowserRowCollection(BrowserColumnMode.cards, [
        const BrowserRowId(101),
        const BrowserRowId(102),
      ]);
      expect(await cards.queryCardIdsAt(1), [102]);

      final notes = BrowserRowCollection(BrowserColumnMode.notes, [
        const BrowserRowId(10),
        const BrowserRowId(20),
      ]);
      final queried = <int>[];
      expect(
        await notes.queryCardIdsAt(1, cardIdsOfNote: (noteId) {
          queried.add(noteId);
          return [201, 202];
        }),
        [201, 202],
      );
      expect(queried, [20]);
    });
  });
}
