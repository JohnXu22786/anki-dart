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
 * Source-derived Reviewer page-finished cases; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Reviewer page-finished effects', () {
    test('requests current-card refresh outside recreation', () {
      for (final showingAnswer in [false, true]) {
        expect(
          planReviewerPageFinishedEffects(
            isAfterRecreation: false,
            showingAnswer: showingAnswer,
          ),
          [ReviewerPageFinishedEffect.updateCurrentCard],
        );
      }
    });

    test('checks mutation signal after showing restored answer', () async {
      final calls = <String>[];
      final requests = <ReviewerPageFinishedEffect>[];

      await executeReviewerPageFinishedEffects(
        planReviewerPageFinishedEffects(
          isAfterRecreation: true,
          showingAnswer: true,
        ),
        isMutationSignalCompleted: () async {
          calls.add('checkMutationSignal');
          return false;
        },
        request: (effect) async {
          requests.add(effect);
          calls.add(effect.name);
        },
      );

      expect(calls, [
        'showAnswer',
        'checkMutationSignal',
        'runStateMutationHook',
      ]);
      expect(requests, [
        ReviewerPageFinishedEffect.showAnswer,
        ReviewerPageFinishedEffect.runStateMutationHook,
      ]);
    });

    test(
      'restored answer omits hook when signal is complete after showAnswer',
      () async {
        final requests = <ReviewerPageFinishedEffect>[];

        await executeReviewerPageFinishedEffects(
          planReviewerPageFinishedEffects(
            isAfterRecreation: true,
            showingAnswer: true,
          ),
          isMutationSignalCompleted: () async {
            expect(requests, [ReviewerPageFinishedEffect.showAnswer]);
            return true;
          },
          request: (effect) async => requests.add(effect),
        );

        expect(requests, [ReviewerPageFinishedEffect.showAnswer]);
      },
    );

    test('restored question only requests question rendering', () {
      expect(
        planReviewerPageFinishedEffects(
          isAfterRecreation: true,
          showingAnswer: false,
        ),
        [ReviewerPageFinishedEffect.showQuestion],
      );
    });

    test(
      'a failed show-answer request prevents the signal check and hook',
      () async {
        final failure = StateError('showAnswer failed');
        final calls = <String>[];
        final requested = <ReviewerPageFinishedEffect>[];

        await expectLater(
          executeReviewerPageFinishedEffects(
            planReviewerPageFinishedEffects(
              isAfterRecreation: true,
              showingAnswer: true,
            ),
            isMutationSignalCompleted: () async {
              calls.add('checkMutationSignal');
              return false;
            },
            request: (effect) async {
              requested.add(effect);
              calls.add(effect.name);
              if (effect == ReviewerPageFinishedEffect.showAnswer) {
                throw failure;
              }
            },
          ),
          throwsA(same(failure)),
        );

        expect(calls, ['showAnswer']);
        expect(requested, [ReviewerPageFinishedEffect.showAnswer]);
      },
    );
  });
}
