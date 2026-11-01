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
 * Source-derived from NoteEditorDestination.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('noteEditorEditFromPreviewerToIntent', () {
    test(
      'writes the caller before the exact card ID and returns the intent',
      () {
        final context = Object();
        final intent = Object();
        final events = <Object?>[];

        final result = noteEditorEditFromPreviewerToIntent(
          context: context,
          cardId: 1234567890123,
          callbacks: NoteEditorEditFromPreviewerIntentCallbacks<Object, Object>(
            createIntent: (actualContext) {
              events.add(('create', actualContext));
              return intent;
            },
            putIntExtra: (target, key, value) {
              events.add(('int', target, key, value));
            },
            putLongExtra: (target, key, value) {
              events.add(('long', target, key, value));
            },
          ),
        );

        expect(result, same(intent));
        expect(events, [
          ('create', context),
          ('int', intent, 'CALLER', NoteEditorCaller.PREVIEWER_EDIT.value),
          ('long', intent, 'editCid', 1234567890123),
        ]);
      },
    );

    test('preserves zero and negative card IDs in the long extra', () {
      for (final cardId in [0, -1]) {
        final intent = Object();
        final values = <(String, int)>[];

        final result = noteEditorEditFromPreviewerToIntent(
          context: Object(),
          cardId: cardId,
          callbacks: NoteEditorEditFromPreviewerIntentCallbacks<Object, Object>(
            createIntent: (_) => intent,
            putIntExtra: (_, key, value) {
              expect(key, 'CALLER');
              expect(value, 9);
            },
            putLongExtra: (_, key, value) => values.add((key, value)),
          ),
        );

        expect(result, same(intent));
        expect(values, [('editCid', cardId)]);
      }
    });

    test('propagates callback failures and stops later operations', () {
      final cases = <({String stage, List<String> reached})>[
        (stage: 'create', reached: ['create']),
        (stage: 'caller', reached: ['create', 'caller']),
        (stage: 'card', reached: ['create', 'caller', 'card']),
      ];

      for (final testCase in cases) {
        final failure = StateError('${testCase.stage} failed');
        final reached = <String>[];
        void invoke(String stage) {
          reached.add(stage);
          if (stage == testCase.stage) throw failure;
        }

        expect(
          () => noteEditorEditFromPreviewerToIntent(
            context: Object(),
            cardId: 42,
            callbacks:
                NoteEditorEditFromPreviewerIntentCallbacks<Object, Object>(
                  createIntent: (_) {
                    invoke('create');
                    return Object();
                  },
                  putIntExtra: (_, key, value) => invoke('caller'),
                  putLongExtra: (_, key, value) => invoke('card'),
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
