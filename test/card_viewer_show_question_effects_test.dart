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
 * Source-derived CardViewerViewModel.showQuestion() cases; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('CardViewer show-question effects', () {
    test('preserves source order, host inputs, and JavaScript shape', () async {
      final calls = <String>[];
      var currentCardReads = 0;

      await runCardViewerShowQuestion<String>(
        publishShowingAnswer: (value) {
          calls.add('showingAnswer:$value');
        },
        awaitCurrentCard: () {
          currentCardReads++;
          calls.add('currentCard$currentCardReads');
          return 'card$currentCardReads';
        },
        readQuestion: (card) {
          calls.add('question:$card');
          return 'raw question';
        },
        escapeMediaFilenames: (text) {
          calls.add('escape:$text');
          return 'escaped $text';
        },
        renderOutput: (card) {
          calls.add('renderOutput:$card');
          return 'rendered media';
        },
        replaceAvRefsWithPlayButtons: (text, renderOutput) {
          calls.add('replace:$text:$renderOutput');
          return 'question with play buttons';
        },
        typeAnswerFilter: (text) {
          calls.add('typeAnswerFilter:$text');
          return 'filtered question';
        },
        readAnswer: (card) {
          calls.add('answer:$card');
          return 'raw answer';
        },
        bodyClassForCard: (card) {
          calls.add('bodyClass:$card');
          return 'card type';
        },
        encodeQuestion: (question) {
          calls.add('encodeQuestion:$question');
          return '"filtered question"';
        },
        encodeAnswer: (answer) {
          calls.add('encodeAnswer:$answer');
          return '"escaped raw answer"';
        },
        emitEval: (script) {
          calls.add('eval:$script');
        },
      );

      expect(calls, [
        'showingAnswer:false',
        'currentCard1',
        'question:card1',
        'escape:raw question',
        'currentCard2',
        'renderOutput:card2',
        'replace:escaped raw question:rendered media',
        'typeAnswerFilter:question with play buttons',
        'answer:card1',
        'escape:raw answer',
        'encodeQuestion:filtered question',
        'encodeAnswer:escaped raw answer',
        'currentCard3',
        'bodyClass:card3',
        'eval:_showQuestion("filtered question", "escaped raw answer", \'card type\');',
      ]);
    });

    test(
      'propagates each host failure after its completed effect prefix',
      () async {
        const stages = [
          'showingAnswer',
          'currentCard1',
          'question',
          'escapeQuestion',
          'currentCard2',
          'renderOutput',
          'replace',
          'typeAnswerFilter',
          'answer',
          'escapeAnswer',
          'encodeQuestion',
          'encodeAnswer',
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

          Future<void> run() => runCardViewerShowQuestion<String>(
            publishShowingAnswer: (_) => failAt('showingAnswer'),
            awaitCurrentCard: () {
              currentCardReads++;
              failAt('currentCard$currentCardReads');
              return 'card';
            },
            readQuestion: (_) {
              failAt('question');
              return 'question';
            },
            escapeMediaFilenames: (text) {
              failAt(text == 'question' ? 'escapeQuestion' : 'escapeAnswer');
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
            readAnswer: (_) {
              failAt('answer');
              return 'answer';
            },
            bodyClassForCard: (_) {
              failAt('bodyClass');
              return 'body';
            },
            encodeQuestion: (_) {
              failAt('encodeQuestion');
              return '"question"';
            },
            encodeAnswer: (_) {
              failAt('encodeAnswer');
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
