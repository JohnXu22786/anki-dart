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
 * Source-derived from CardTemplateBrowserAppearanceEditor.Result in AnkiDroid
 * 2.25.3; see ANKIDROID_UPSTREAM.md. The pinned source has no direct tests for
 * these methods.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('browser appearance result extraction', () {
    test('null intent returns null without reading either format', () {
      var questionWasRead = false;
      var answerWasRead = false;

      expect(
        browserAppearanceResultFromIntent(
          hasIntent: false,
          readQuestionFormat: () {
            questionWasRead = true;
            return 'question';
          },
          readAnswerFormat: () {
            answerWasRead = true;
            return 'answer';
          },
        ),
        isNull,
      );
      expect(questionWasRead, isFalse);
      expect(answerWasRead, isFalse);
    });

    test('reads question before answer', () {
      final reads = <String>[];

      final result = browserAppearanceResultFromIntent(
        hasIntent: true,
        readQuestionFormat: () {
          reads.add('question');
          return 'q';
        },
        readAnswerFormat: () {
          reads.add('answer');
          return 'a';
        },
      );

      expect(reads, ['question', 'answer']);
      expect(result!.question, 'q');
      expect(result.answer, 'a');
    });

    test('null formats use the source empty-string default independently', () {
      final result = browserAppearanceResultFromIntent(
        hasIntent: true,
        readQuestionFormat: () => null,
        readAnswerFormat: () => 'answer',
      );
      final otherResult = browserAppearanceResultFromIntent(
        hasIntent: true,
        readQuestionFormat: () => 'question',
        readAnswerFormat: () => null,
      );

      expect(result!.question, '');
      expect(result.answer, 'answer');
      expect(otherResult!.question, 'question');
      expect(otherResult.answer, '');
    });

    test('question exception returns null and does not read answer', () {
      final exception = FormatException('question read failed');
      var answerWasRead = false;

      expect(
        browserAppearanceResultFromIntent(
          hasIntent: true,
          readQuestionFormat: () => throw exception,
          readAnswerFormat: () {
            answerWasRead = true;
            return 'answer';
          },
        ),
        isNull,
      );
      expect(answerWasRead, isFalse);
    });

    test('answer exception returns null', () {
      expect(
        browserAppearanceResultFromIntent(
          hasIntent: true,
          readQuestionFormat: () => 'question',
          readAnswerFormat: () => throw FormatException('answer read failed'),
        ),
        isNull,
      );
    });

    test('Error propagates and does not read answer', () {
      final error = StateError('question read error');
      var answerWasRead = false;

      expect(
        () => browserAppearanceResultFromIntent(
          hasIntent: true,
          readQuestionFormat: () => throw error,
          readAnswerFormat: () {
            answerWasRead = true;
            return 'answer';
          },
        ),
        throwsA(same(error)),
      );
      expect(answerWasRead, isFalse);
    });
  });

  group('browser appearance result application', () {
    test('applies question before answer', () {
      final result = BrowserAppearanceResult(
        question: 'question',
        answer: 'answer',
      );
      final applied = <String>[];

      result.applyTo(
        setBqfmt: (value) => applied.add('bqfmt:$value'),
        setBafmt: (value) => applied.add('bafmt:$value'),
      );

      expect(applied, ['bqfmt:question', 'bafmt:answer']);
    });

    test('passes both formats to the corresponding host setters unchanged', () {
      const question = ' {{Front}}\n{{Back}} ';
      const answer = '<div>{{FrontSide}}</div>\n';
      final result = BrowserAppearanceResult(
        question: question,
        answer: answer,
      );
      String? bqfmt;
      String? bafmt;

      result.applyTo(
        setBqfmt: (value) => bqfmt = value,
        setBafmt: (value) => bafmt = value,
      );

      expect(bqfmt, question);
      expect(bafmt, answer);
    });

    test('first setter exception propagates and skips the answer setter', () {
      final result = BrowserAppearanceResult(question: 'q', answer: 'a');
      final exception = StateError('question setter failed');
      var answerWasSet = false;

      expect(
        () => result.applyTo(
          setBqfmt: (_) => throw exception,
          setBafmt: (_) => answerWasSet = true,
        ),
        throwsA(same(exception)),
      );
      expect(answerWasSet, isFalse);
    });
  });
}
