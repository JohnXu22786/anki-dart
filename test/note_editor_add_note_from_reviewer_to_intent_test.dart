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
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('noteEditorAddNoteFromReviewerToIntent', () {
    test(
      'writes caller and omits null animation, returning the same intent',
      () {
        final context = Object();
        final intent = Object();
        final events = <Object?>[];

        final result = noteEditorAddNoteFromReviewerToIntent(
          context: context,
          animation: null,
          callbacks:
              NoteEditorAddNoteFromReviewerIntentCallbacks<
                Object,
                Object,
                Object
              >(
                createIntent: (actualContext) {
                  events.add(('create', actualContext));
                  return intent;
                },
                putIntExtra: (target, key, value) {
                  events.add(('int', target, key, value));
                },
                putParcelableExtra: (target, key, value) {
                  events.add(('parcelable', target, key, value));
                },
              ),
        );

        expect(result, same(intent));
        expect(events, [('create', context), ('int', intent, 'CALLER', 11)]);
      },
    );

    test('passes non-null animation unchanged after caller', () {
      final intent = Object();
      final animation = Object();
      final events = <Object?>[];

      final result = noteEditorAddNoteFromReviewerToIntent(
        context: Object(),
        animation: animation,
        callbacks:
            NoteEditorAddNoteFromReviewerIntentCallbacks<
              Object,
              Object,
              Object
            >(
              createIntent: (_) => intent,
              putIntExtra: (target, key, value) {
                events.add(('int', target, key, value));
              },
              putParcelableExtra: (target, key, value) {
                events.add(('parcelable', target, key, value));
              },
            ),
      );

      expect(result, same(intent));
      expect(events, [
        ('int', intent, 'CALLER', 11),
        ('parcelable', intent, 'finishAnimation', animation),
      ]);
    });

    test('propagates callback failures and stops later operations', () {
      final cases = <({String stage, List<String> reached})>[
        (stage: 'create', reached: ['create']),
        (stage: 'caller', reached: ['create', 'caller']),
        (stage: 'animation', reached: ['create', 'caller', 'animation']),
      ];

      for (final testCase in cases) {
        final failure = StateError('${testCase.stage} failed');
        final reached = <String>[];
        void invoke(String stage) {
          reached.add(stage);
          if (stage == testCase.stage) throw failure;
        }

        expect(
          () => noteEditorAddNoteFromReviewerToIntent(
            context: Object(),
            animation: Object(),
            callbacks:
                NoteEditorAddNoteFromReviewerIntentCallbacks<
                  Object,
                  Object,
                  Object
                >(
                  createIntent: (_) {
                    invoke('create');
                    return Object();
                  },
                  putIntExtra: (target, key, value) => invoke('caller'),
                  putParcelableExtra: (target, key, value) =>
                      invoke('animation'),
                ),
          ),
          throwsA(same(failure)),
          reason: 'failure at ${testCase.stage} should propagate',
        );
        expect(reached, testCase.reached, reason: testCase.stage);
      }
    });
  });
}
