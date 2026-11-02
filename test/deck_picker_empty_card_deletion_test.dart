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
 * Source-derived from DeckPickerViewModel.kt:228–245 in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('deckPickerEmptyCardDeletionIds', () {
    test('retains the first card of notes scheduled for deletion', () {
      final report = DeckPickerEmptyCardDeletionReport([
        DeckPickerEmptyCardDeletionNote(
          willDeleteNote: true,
          cardIds: [10, 11, 12],
        ),
      ]);

      expect(deckPickerEmptyCardDeletionIds(report, preserveNotes: true), [
        11,
        12,
      ]);
    });

    test(
      'includes every card when preservation is disabled or note survives',
      () {
        final report = DeckPickerEmptyCardDeletionReport([
          DeckPickerEmptyCardDeletionNote(
            willDeleteNote: true,
            cardIds: [10, 11],
          ),
          DeckPickerEmptyCardDeletionNote(
            willDeleteNote: false,
            cardIds: [20, 21],
          ),
        ]);

        expect(deckPickerEmptyCardDeletionIds(report, preserveNotes: false), [
          10,
          11,
          20,
          21,
        ]);
        expect(deckPickerEmptyCardDeletionIds(report, preserveNotes: true), [
          11,
          20,
          21,
        ]);
      },
    );

    test('empty and single-card notes follow drop-one semantics', () {
      final report = DeckPickerEmptyCardDeletionReport([
        DeckPickerEmptyCardDeletionNote(willDeleteNote: true, cardIds: []),
        DeckPickerEmptyCardDeletionNote(willDeleteNote: true, cardIds: [30]),
        DeckPickerEmptyCardDeletionNote(willDeleteNote: false, cardIds: [40]),
      ]);

      expect(deckPickerEmptyCardDeletionIds(report, preserveNotes: true), [40]);
      expect(
        deckPickerEmptyCardDeletionIds(
          DeckPickerEmptyCardDeletionReport([
            DeckPickerEmptyCardDeletionNote(
              willDeleteNote: true,
              cardIds: [50],
            ),
          ]),
          preserveNotes: true,
        ),
        isEmpty,
      );
    });

    test('keeps report order and duplicate card IDs', () {
      final report = DeckPickerEmptyCardDeletionReport([
        DeckPickerEmptyCardDeletionNote(willDeleteNote: false, cardIds: [2, 2]),
        DeckPickerEmptyCardDeletionNote(
          willDeleteNote: true,
          cardIds: [1, 3, 3],
        ),
      ]);

      expect(deckPickerEmptyCardDeletionIds(report, preserveNotes: true), [
        2,
        2,
        3,
        3,
      ]);
    });

    test('does not mutate the report or its card ID lists', () {
      final firstCardIds = [1, 2, 2];
      final secondCardIds = [3];
      final report = DeckPickerEmptyCardDeletionReport([
        DeckPickerEmptyCardDeletionNote(
          willDeleteNote: true,
          cardIds: firstCardIds,
        ),
        DeckPickerEmptyCardDeletionNote(
          willDeleteNote: false,
          cardIds: secondCardIds,
        ),
      ]);
      final notesBefore = List.of(report.notes);
      final firstCardIdsBefore = List.of(firstCardIds);
      final secondCardIdsBefore = List.of(secondCardIds);

      deckPickerEmptyCardDeletionIds(report, preserveNotes: true);

      expect(report.notes, notesBefore);
      expect(firstCardIds, firstCardIdsBefore);
      expect(secondCardIds, secondCardIdsBefore);
    });
  });
}
