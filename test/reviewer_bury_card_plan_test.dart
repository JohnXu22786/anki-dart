/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived Reviewer bury-card effect cases; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Reviewer bury-card plan', () {
    test('buries only the supplied card before feedback and reload', () async {
      final events = <String>[];
      List<int>? buriedCardIds;

      await executeReviewerBuryCardPlan(
        cardId: 821,
        buryCards: (cardIds) async {
          events.add('bury');
          buriedCardIds = cardIds;
          return 1;
        },
        localizedFeedbackForCount: (count) {
          events.add('localize');
          return '$count note buried';
        },
        showFeedback: (message) async {
          events.add('feedback: $message');
        },
        reloadCurrentCard: () async => events.add('reload'),
      );

      expect(buriedCardIds, [821]);
      expect(events, ['bury', 'localize', 'feedback: 1 note buried', 'reload']);
    });

    test(
      'passes scheduler result count into host-localized feedback',
      () async {
        const message = '  3 notes buried — 已埋葬  ';
        int? localizedCount;
        String? feedbackMessage;

        await executeReviewerBuryCardPlan(
          cardId: 1,
          buryCards: (_) async => 3,
          localizedFeedbackForCount: (count) {
            localizedCount = count;
            return message;
          },
          showFeedback: (value) async => feedbackMessage = value,
          reloadCurrentCard: () async {},
        );

        expect(localizedCount, 3);
        expect(feedbackMessage, message);
      },
    );

    test('a bury failure prevents feedback and reload', () async {
      final performed = <String>[];

      await expectLater(
        executeReviewerBuryCardPlan(
          cardId: 73,
          buryCards: (_) async {
            performed.add('bury');
            throw StateError('scheduler operation failed');
          },
          localizedFeedbackForCount: (_) {
            performed.add('localize');
            return 'Buried';
          },
          showFeedback: (_) async => performed.add('feedback'),
          reloadCurrentCard: () async => performed.add('reload'),
        ),
        throwsStateError,
      );

      expect(performed, ['bury']);
    });
  });
}
