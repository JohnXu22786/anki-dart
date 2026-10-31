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
 * Source-derived from CardTemplateEditor.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('flipCardTemplateQA', () {
    test('uses the greedy DOTALL match and trims capture two', () {
      String? newQuestion;
      String? newAnswer;

      flipCardTemplateQA(
        question: 'original front',
        answer: 'prefix first<hr id=answer> middle\n<hr id=answer>  back  ',
        setQuestion: (value) => newQuestion = value,
        setAnswer: (value) => newAnswer = value,
      );

      expect(newQuestion, 'back');
      expect(newAnswer, '{{FrontSide}}\n\n<hr id=answer>\n\noriginal front');
    });

    test('trims only code units at or below U+0020', () {
      String? newQuestion;

      flipCardTemplateQA(
        question: '',
        answer: 'x<hr id=answer> \t\n\u00a0text\u00a0\r ',
        setQuestion: (value) => newQuestion = value,
        setAnswer: (_) {},
      );

      expect(newQuestion, '\u00a0text\u00a0');
    });

    test('without a match removes every literal FrontSide marker', () {
      String? newQuestion;

      flipCardTemplateQA(
        question: 'front',
        answer: r'{{FrontSide}} + {{FrontSide}}',
        setQuestion: (value) => newQuestion = value,
        setAnswer: (_) {},
      );

      expect(newQuestion, ' + ');
    });

    test(
      'preserves unmatched newline content and builds exact answer text',
      () {
        String? newQuestion;
        String? newAnswer;

        flipCardTemplateQA(
          question: 'front\r\nline',
          answer: 'no separator\n{{FrontSide}}\n',
          setQuestion: (value) => newQuestion = value,
          setAnswer: (value) => newAnswer = value,
        );

        expect(newQuestion, 'no separator\n\n');
        expect(newAnswer, '{{FrontSide}}\n\n<hr id=answer>\n\nfront\r\nline');
      },
    );

    test(
      'assigns the question before the answer and stops on question failure',
      () {
        final calls = <String>[];
        final failure = StateError('question assignment failed');

        expect(
          () => flipCardTemplateQA(
            question: 'front',
            answer: 'no separator',
            setQuestion: (_) {
              calls.add('question');
              throw failure;
            },
            setAnswer: (_) => calls.add('answer'),
          ),
          throwsA(same(failure)),
        );
        expect(calls, ['question']);
      },
    );

    test('propagates answer assignment failure after question assignment', () {
      final calls = <String>[];
      final failure = StateError('answer assignment failed');

      expect(
        () => flipCardTemplateQA(
          question: 'front',
          answer: 'no separator',
          setQuestion: (_) => calls.add('question'),
          setAnswer: (_) {
            calls.add('answer');
            throw failure;
          },
        ),
        throwsA(same(failure)),
      );
      expect(calls, ['question', 'answer']);
    });
  });
}
