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
 * Source-derived Card Browser deletion effect cases; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Card Browser selected-note deletion plan', () {
    test('clears a pane row whose ID is selected before deletion', () async {
      final events = <String>[];
      final cardIds = [7, 3, 7];
      List<int>? removedCardIds;

      await executeBrowserDeleteSelectedNotesPlan(
        paneRowCardOrNoteId: 3,
        cardIds: cardIds,
        clearPaneRow: () => events.add('clear pane row'),
        removeNotes: (ids) async {
          events.add('remove notes');
          removedCardIds = ids;
          return 2;
        },
        endMultiSelectModeOther: () => events.add('end multi-select'),
        refreshSearch: () => events.add('refresh search'),
      );

      expect(removedCardIds, same(cardIds));
      expect(events, [
        'clear pane row',
        'remove notes',
        'end multi-select',
        'refresh search',
      ]);
    });

    test('leaves a pane row whose ID is not selected', () async {
      final events = <String>[];

      await executeBrowserDeleteSelectedNotesPlan(
        paneRowCardOrNoteId: 9,
        cardIds: [7, 3],
        clearPaneRow: () => events.add('clear pane row'),
        removeNotes: (_) async {
          events.add('remove notes');
          return 1;
        },
        endMultiSelectModeOther: () => events.add('end multi-select'),
        refreshSearch: () => events.add('refresh search'),
      );

      expect(events, ['remove notes', 'end multi-select', 'refresh search']);
    });

    test(
      'passes empty and duplicate ID lists unchanged and returns count',
      () async {
        for (final cardIds in <List<int>>[
          [],
          [7, 7, 3],
        ]) {
          List<int>? removedCardIds;

          final count = await executeBrowserDeleteSelectedNotesPlan(
            paneRowCardOrNoteId: null,
            cardIds: cardIds,
            clearPaneRow: () => fail('no pane row to clear'),
            removeNotes: (ids) async {
              removedCardIds = ids;
              return 4;
            },
            endMultiSelectModeOther: () {},
            refreshSearch: () {},
          );

          expect(removedCardIds, same(cardIds));
          expect(removedCardIds, cardIds);
          expect(count, 4);
        }
      },
    );

    test(
      'deletion failure prevents multi-select end and search refresh',
      () async {
        final events = <String>[];

        await expectLater(
          executeBrowserDeleteSelectedNotesPlan(
            paneRowCardOrNoteId: 7,
            cardIds: [7],
            clearPaneRow: () => events.add('clear pane row'),
            removeNotes: (_) async {
              events.add('remove notes');
              throw StateError('undoable operation failed');
            },
            endMultiSelectModeOther: () => events.add('end multi-select'),
            refreshSearch: () => events.add('refresh search'),
          ),
          throwsStateError,
        );

        expect(events, ['clear pane row', 'remove notes']);
      },
    );
  });
}
