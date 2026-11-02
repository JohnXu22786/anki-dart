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
 * Source-derived Reviewer current-card refresh cases; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Reviewer current-card update effects', () {
    test('null queue state publishes only the no-more-cards result', () async {
      final calls = <String>[];

      await executeReviewerCurrentCardUpdate<Object, Object, Object>(
        hasQueueState: false,
        timeboxReached: null,
        topCard: null,
        studyCountsSourceState: null,
        publishFinishResult: (result) async => calls.add('finish:$result'),
        publishTimeboxReached: (_) async => calls.add('timebox'),
        setCurrentCard: (_) async => calls.add('setCurrentCard'),
        setupAnswerTimer: (_) async => calls.add('setupAnswerTimer'),
        notifyAutoAdvanceCardChange: (_) async => calls.add('autoAdvance'),
        emitCardUpdated: () async => calls.add('cardUpdated'),
        showQuestion: () async => calls.add('showQuestion'),
        loadAndPlayQuestionMedia: () async => calls.add('media'),
        publishCanBuryNote: (_) async => calls.add('canBury'),
        publishCanSuspendNote: (_) async => calls.add('canSuspend'),
        publishStudyCounts: (_) async => calls.add('counts'),
      );

      expect(calls, ['finish:52']);
    });

    test('timebox state publishes the same event and returns', () async {
      final calls = <String>[];
      final timebox = Object();
      Object? publishedTimebox;

      await executeReviewerCurrentCardUpdate<Object, Object, Object>(
        hasQueueState: true,
        timeboxReached: timebox,
        topCard: null,
        studyCountsSourceState: null,
        publishFinishResult: (_) async => calls.add('finish'),
        publishTimeboxReached: (event) async {
          calls.add('timebox');
          publishedTimebox = event;
        },
        setCurrentCard: (_) async => calls.add('setCurrentCard'),
        setupAnswerTimer: (_) async => calls.add('setupAnswerTimer'),
        notifyAutoAdvanceCardChange: (_) async => calls.add('autoAdvance'),
        emitCardUpdated: () async => calls.add('cardUpdated'),
        showQuestion: () async => calls.add('showQuestion'),
        loadAndPlayQuestionMedia: () async => calls.add('media'),
        publishCanBuryNote: (_) async => calls.add('canBury'),
        publishCanSuspendNote: (_) async => calls.add('canSuspend'),
        publishStudyCounts: (_) async => calls.add('counts'),
      );

      expect(calls, ['timebox']);
      expect(publishedTimebox, same(timebox));
    });

    test(
      'normal state preserves callback order and host object identity',
      () async {
        final calls = <String>[];
        final card = Object();
        final state = Object();
        final cards = <Object>[];
        Object? countsState;

        await executeReviewerCurrentCardUpdate<Object, Object, Object>(
          hasQueueState: true,
          timeboxReached: null,
          topCard: card,
          studyCountsSourceState: state,
          publishFinishResult: (_) async => calls.add('finish'),
          publishTimeboxReached: (_) async => calls.add('timebox'),
          setCurrentCard: (value) async {
            calls.add('setCurrentCard');
            cards.add(value);
          },
          setupAnswerTimer: (value) async {
            calls.add('setupAnswerTimer');
            cards.add(value);
          },
          notifyAutoAdvanceCardChange: (value) async {
            calls.add('autoAdvance');
            cards.add(value);
          },
          emitCardUpdated: () async => calls.add('cardUpdated'),
          showQuestion: () async => calls.add('showQuestion'),
          loadAndPlayQuestionMedia: () async => calls.add('media'),
          publishCanBuryNote: (value) async {
            calls.add('canBury');
            cards.add(value);
          },
          publishCanSuspendNote: (value) async {
            calls.add('canSuspend');
            cards.add(value);
          },
          publishStudyCounts: (value) async {
            calls.add('counts');
            countsState = value;
          },
        );

        expect(calls, [
          'setCurrentCard',
          'setupAnswerTimer',
          'autoAdvance',
          'cardUpdated',
          'showQuestion',
          'media',
          'canBury',
          'canSuspend',
          'counts',
        ]);
        expect(cards, everyElement(same(card)));
        expect(countsState, same(state));
      },
    );

    test('a failed effect propagates and stops all later effects', () async {
      final failure = StateError('timer failed');
      final calls = <String>[];

      await expectLater(
        executeReviewerCurrentCardUpdate<Object, Object, Object>(
          hasQueueState: true,
          timeboxReached: null,
          topCard: Object(),
          studyCountsSourceState: Object(),
          publishFinishResult: (_) async => calls.add('finish'),
          publishTimeboxReached: (_) async => calls.add('timebox'),
          setCurrentCard: (_) async => calls.add('setCurrentCard'),
          setupAnswerTimer: (_) async {
            calls.add('setupAnswerTimer');
            throw failure;
          },
          notifyAutoAdvanceCardChange: (_) async => calls.add('autoAdvance'),
          emitCardUpdated: () async => calls.add('cardUpdated'),
          showQuestion: () async => calls.add('showQuestion'),
          loadAndPlayQuestionMedia: () async => calls.add('media'),
          publishCanBuryNote: (_) async => calls.add('canBury'),
          publishCanSuspendNote: (_) async => calls.add('canSuspend'),
          publishStudyCounts: (_) async => calls.add('counts'),
        ),
        throwsA(same(failure)),
      );

      expect(calls, ['setCurrentCard', 'setupAnswerTimer']);
    });
  });
}
