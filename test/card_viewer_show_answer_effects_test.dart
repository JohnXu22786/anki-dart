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
 * Source-derived CardViewerViewModel.showAnswer() cases; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('CardViewer show-answer effects', () {
    test('preserves source order, host inputs, and JavaScript shape', () async {
      final calls = <String>[];
      var currentCardReads = 0;

      await runCardViewerShowAnswer<String>(
        publishShowingAnswer: (value) {
          calls.add('showingAnswer:$value');
        },
        notifyCardSideChange: () {
          calls.add('cardSideChange');
        },
        awaitCurrentCard: () {
          currentCardReads++;
          calls.add('currentCard$currentCardReads');
          return 'card';
        },
        readAnswer: (card) {
          calls.add('answer:$card');
          return 'raw answer';
        },
        escapeMediaFilenames: (text) {
          calls.add('escape:$text');
          return 'escaped answer';
        },
        renderOutput: (card) {
          calls.add('renderOutput:$card');
          return 'rendered media';
        },
        replaceAvRefsWithPlayButtons: (text, renderOutput) {
          calls.add('replace:$text:$renderOutput');
          return 'answer with play buttons';
        },
        typeAnswerFilter: (text) {
          calls.add('typeAnswerFilter:$text');
          return 'filtered answer';
        },
        bodyClassForCard: (card) {
          calls.add('bodyClass:$card');
          return 'card type';
        },
        encodeAnswer: (answer) {
          calls.add('encode:$answer');
          return '"filtered answer"';
        },
        emitEval: (script) {
          calls.add('eval:$script');
        },
      );

      expect(calls, [
        'showingAnswer:true',
        'cardSideChange',
        'currentCard1',
        'answer:card',
        'escape:raw answer',
        'currentCard2',
        'renderOutput:card',
        'replace:escaped answer:rendered media',
        'typeAnswerFilter:answer with play buttons',
        'encode:filtered answer',
        'currentCard3',
        'bodyClass:card',
        'eval:_showAnswer("filtered answer", \'card type\');',
      ]);
    });

    test(
      'propagates each host failure after its completed effect prefix',
      () async {
        const stages = [
          'showingAnswer',
          'cardSideChange',
          'currentCard1',
          'answer',
          'escape',
          'currentCard2',
          'renderOutput',
          'replace',
          'typeAnswerFilter',
          'encode',
          'currentCard3',
          'bodyClass',
          'eval',
        ];

        for (
          var failureIndex = 0;
          failureIndex < stages.length;
          failureIndex++
        ) {
          final failureStage = stages[failureIndex];
          final error = StateError(failureStage);
          final calls = <String>[];
          var currentCardReads = 0;

          Object? failAt(String stage) {
            calls.add(stage);
            if (stage == failureStage) throw error;
            return null;
          }

          Future<void> run() => runCardViewerShowAnswer<String>(
            publishShowingAnswer: (_) => failAt('showingAnswer'),
            notifyCardSideChange: () => failAt('cardSideChange'),
            awaitCurrentCard: () {
              currentCardReads++;
              failAt('currentCard$currentCardReads');
              return 'card';
            },
            readAnswer: (_) {
              failAt('answer');
              return 'raw';
            },
            escapeMediaFilenames: (_) {
              failAt('escape');
              return 'escaped';
            },
            renderOutput: (_) {
              failAt('renderOutput');
              return 'rendered';
            },
            replaceAvRefsWithPlayButtons: (_, __) {
              failAt('replace');
              return 'replaced';
            },
            typeAnswerFilter: (_) {
              failAt('typeAnswerFilter');
              return 'filtered';
            },
            bodyClassForCard: (_) {
              failAt('bodyClass');
              return 'body';
            },
            encodeAnswer: (_) {
              failAt('encode');
              return '"answer"';
            },
            emitEval: (_) => failAt('eval'),
          );

          await expectLater(run(), throwsA(same(error)));
          expect(calls, stages.take(failureIndex + 1), reason: failureStage);
        }
      },
    );
  });
}
