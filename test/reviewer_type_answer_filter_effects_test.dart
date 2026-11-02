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
 * Source-derived Reviewer type-answer filter cases; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Reviewer type-answer filter effects', () {
    test(
      'answer side emits null before returning host filter result',
      () async {
        final calls = <String>[];
        final typeAnswer = Object();
        final hostResult = StringBuffer('filtered');
        Object? emitted;

        final result = await executeReviewerTypeAnswerFilter<Object>(
          showingAnswer: true,
          typeAnswer: typeAnswer,
          text: 'question and answer',
          typedAnswer: 'typed',
          useHtmlTypeAnswer: true,
          emitTypeAnswer: (value) async {
            calls.add('emit');
            emitted = value;
          },
          filterAnswer: (text, answer, typedAnswer) {
            calls.add('answer');
            expect(text, 'question and answer');
            expect(answer, same(typeAnswer));
            expect(typedAnswer, 'typed');
            return hostResult.toString();
          },
          filterQuestion: (_, __) {
            calls.add('question');
            return 'question-filtered';
          },
          removeTags: (_) {
            calls.add('removeTags');
            return 'tags-removed';
          },
        );

        expect(calls, ['emit', 'answer']);
        expect(emitted, isNull);
        expect(result, 'filtered');
      },
    );

    test('answer side with null TypeAnswer returns original text', () async {
      final calls = <String>[];

      final result = await executeReviewerTypeAnswerFilter<Object>(
        showingAnswer: true,
        typeAnswer: null,
        text: 'original',
        typedAnswer: 'typed',
        useHtmlTypeAnswer: false,
        emitTypeAnswer: (value) async {
          calls.add('emit');
          expect(value, isNull);
        },
        filterAnswer: (_, __, ___) {
          calls.add('answer');
          return 'unexpected';
        },
        filterQuestion: (_, __) {
          calls.add('question');
          return 'unexpected';
        },
        removeTags: (_) {
          calls.add('removeTags');
          return 'unexpected';
        },
      );

      expect(calls, ['emit']);
      expect(result, 'original');
    });

    test(
      'HTML question side emits TypeAnswer before question filter',
      () async {
        final calls = <String>[];
        final typeAnswer = Object();
        Object? emitted;

        final result = await executeReviewerTypeAnswerFilter<Object>(
          showingAnswer: false,
          typeAnswer: typeAnswer,
          text: 'question',
          typedAnswer: 'typed',
          useHtmlTypeAnswer: true,
          emitTypeAnswer: (value) async {
            calls.add('emit');
            emitted = value;
          },
          filterAnswer: (_, __, ___) => 'unexpected',
          filterQuestion: (text, answer) {
            calls.add('question');
            expect(text, 'question');
            expect(answer, same(typeAnswer));
            return 'host-question-result';
          },
          removeTags: (_) {
            calls.add('removeTags');
            return 'unexpected';
          },
        );

        expect(calls, ['emit', 'question']);
        expect(emitted, same(typeAnswer));
        expect(result, 'host-question-result');
      },
    );

    test(
      'HTML question side with null TypeAnswer returns original text',
      () async {
        final calls = <String>[];

        final result = await executeReviewerTypeAnswerFilter<Object>(
          showingAnswer: false,
          typeAnswer: null,
          text: 'original',
          typedAnswer: 'typed',
          useHtmlTypeAnswer: true,
          emitTypeAnswer: (value) async {
            calls.add('emit');
            expect(value, isNull);
          },
          filterAnswer: (_, __, ___) {
            calls.add('answer');
            return 'unexpected';
          },
          filterQuestion: (_, __) {
            calls.add('question');
            return 'unexpected';
          },
          removeTags: (_) {
            calls.add('removeTags');
            return 'unexpected';
          },
        );

        expect(calls, ['emit']);
        expect(result, 'original');
      },
    );

    test('non-HTML question side always removes tags after emission', () async {
      for (final typeAnswer in <Object?>[Object(), null]) {
        final calls = <String>[];
        Object? emitted;

        final result = await executeReviewerTypeAnswerFilter<Object>(
          showingAnswer: false,
          typeAnswer: typeAnswer,
          text: '<b>question</b>',
          typedAnswer: 'typed',
          useHtmlTypeAnswer: false,
          emitTypeAnswer: (value) async {
            calls.add('emit');
            emitted = value;
          },
          filterAnswer: (_, __, ___) => 'unexpected',
          filterQuestion: (_, __) {
            calls.add('question');
            return 'unexpected';
          },
          removeTags: (text) {
            calls.add('removeTags');
            expect(text, '<b>question</b>');
            return 'plain';
          },
        );

        expect(calls, ['emit', 'removeTags']);
        expect(emitted, same(typeAnswer));
        expect(result, 'plain');
      }
    });

    test('emission failure stops before any filtering callback', () async {
      final calls = <String>[];
      final failure = StateError('emit failed');

      await expectLater(
        executeReviewerTypeAnswerFilter<Object>(
          showingAnswer: true,
          typeAnswer: Object(),
          text: 'text',
          typedAnswer: 'typed',
          useHtmlTypeAnswer: true,
          emitTypeAnswer: (_) async {
            calls.add('emit');
            throw failure;
          },
          filterAnswer: (_, __, ___) {
            calls.add('answer');
            return 'unexpected';
          },
          filterQuestion: (_, __) {
            calls.add('question');
            return 'unexpected';
          },
          removeTags: (_) {
            calls.add('removeTags');
            return 'unexpected';
          },
        ),
        throwsA(same(failure)),
      );

      expect(calls, ['emit']);
    });

    test(
      'filter failures propagate after emission and stop later callbacks',
      () async {
        final failure = StateError('filter failed');
        final scenarios =
            <
              ({
                bool showingAnswer,
                bool useHtmlTypeAnswer,
                String expectedCallback,
              })
            >[
              (
                showingAnswer: true,
                useHtmlTypeAnswer: true,
                expectedCallback: 'answer',
              ),
              (
                showingAnswer: false,
                useHtmlTypeAnswer: true,
                expectedCallback: 'question',
              ),
              (
                showingAnswer: false,
                useHtmlTypeAnswer: false,
                expectedCallback: 'removeTags',
              ),
            ];

        for (final scenario in scenarios) {
          final calls = <String>[];
          await expectLater(
            executeReviewerTypeAnswerFilter<Object>(
              showingAnswer: scenario.showingAnswer,
              typeAnswer: Object(),
              text: 'text',
              typedAnswer: 'typed',
              useHtmlTypeAnswer: scenario.useHtmlTypeAnswer,
              emitTypeAnswer: (_) async => calls.add('emit'),
              filterAnswer: (_, __, ___) {
                calls.add('answer');
                if (scenario.expectedCallback == 'answer') {
                  throw failure;
                }
                return 'unexpected';
              },
              filterQuestion: (_, __) {
                calls.add('question');
                if (scenario.expectedCallback == 'question') {
                  throw failure;
                }
                return 'unexpected';
              },
              removeTags: (_) {
                calls.add('removeTags');
                if (scenario.expectedCallback == 'removeTags') {
                  throw failure;
                }
                return 'unexpected';
              },
            ),
            throwsA(same(failure)),
          );

          expect(calls, ['emit', scenario.expectedCallback]);
        }
      },
    );
  });
}
