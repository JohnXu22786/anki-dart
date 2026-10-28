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
 * Source-derived Reviewer delete-note effect cases; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Reviewer delete-note plan', () {
    test('passes one card ID and runs count feedback before reload', () async {
      final events = <String>[];
      List<int>? removedCardIds;
      int? localizedCount;
      String? feedbackMessage;
      const message = '  2 cards deleted — تم الحذف  ';

      await executeReviewerDeleteNotePlan(
        cardId: 821,
        removeNotes: (cardIds) async {
          events.add('remove');
          removedCardIds = cardIds;
          return 2;
        },
        localizedFeedbackForCount: (count) {
          events.add('localize');
          localizedCount = count;
          return message;
        },
        showFeedback: (value) async {
          events.add('feedback');
          feedbackMessage = value;
        },
        reloadCurrentCard: () async => events.add('reload'),
      );

      expect(removedCardIds, [821]);
      expect(localizedCount, 2);
      expect(feedbackMessage, message);
      expect(events, ['remove', 'localize', 'feedback', 'reload']);
    });

    test(
      'a deletion failure prevents localization, feedback, and reload',
      () async {
        final events = <String>[];

        await expectLater(
          executeReviewerDeleteNotePlan(
            cardId: 73,
            removeNotes: (_) async {
              events.add('remove');
              throw StateError('undoable operation failed');
            },
            localizedFeedbackForCount: (_) {
              events.add('localize');
              return 'Deleted';
            },
            showFeedback: (_) async => events.add('feedback'),
            reloadCurrentCard: () async => events.add('reload'),
          ),
          throwsStateError,
        );

        expect(events, ['remove']);
      },
    );
  });
}
