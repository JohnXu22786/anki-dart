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
 *
 * Source-derived from NoteEditorDestination.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('noteEditorEditSelectionToIntent', () {
    test('writes exact extras in source order and returns the same intent', () {
      final context = Object();
      final intent = Object();
      final animation = Object();
      final cardIds = [101, 202, 101];
      final events = <Object?>[];
      List<int>? writtenCardIds;

      final result = noteEditorEditSelectionToIntent(
        context: context,
        cardIds: cardIds,
        animation: animation,
        inCardBrowserActivity: true,
        callbacks:
            NoteEditorEditSelectionIntentCallbacks<Object, Object, Object>(
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
              putLongArrayExtra: (target, key, value) {
                writtenCardIds = value;
                events.add(('longArray', target, key, value.length));
              },
              putParcelableExtra: (target, key, value) {
                events.add(('parcelable', target, key, value));
              },
              putBooleanExtra: (target, key, value) {
                events.add(('boolean', target, key, value));
              },
            ),
      );

      cardIds[0] = 999;
      expect(result, same(intent));
      expect(writtenCardIds, [101, 202, 101]);
      expect(writtenCardIds, isNot(same(cardIds)));
      expect(events, [
        ('create', context),
        ('int', intent, 'CALLER', NoteEditorCaller.EDIT.value),
        ('long', intent, 'CARD_ID', 101),
        ('longArray', intent, 'CARD_IDS', 3),
        ('parcelable', intent, 'finishAnimation', animation),
        ('boolean', intent, 'inCardBrowserActivity', true),
      ]);
    });

    test('empty IDs fail after caller write and before later extras', () {
      final intent = Object();
      final events = <Object?>[];

      expect(
        () => noteEditorEditSelectionToIntent(
          context: Object(),
          cardIds: const [],
          animation: Object(),
          inCardBrowserActivity: false,
          callbacks:
              NoteEditorEditSelectionIntentCallbacks<Object, Object, Object>(
                createIntent: (_) => intent,
                putIntExtra: (target, key, value) {
                  events.add(('int', target, key, value));
                },
                putLongExtra: (_, key, value) => events.add(('long', key)),
                putLongArrayExtra: (_, key, value) =>
                    events.add(('longArray', key)),
                putParcelableExtra: (_, key, value) =>
                    events.add(('parcelable', key)),
                putBooleanExtra: (_, key, value) =>
                    events.add(('boolean', key)),
              ),
        ),
        throwsStateError,
      );

      expect(events, [('int', intent, 'CALLER', NoteEditorCaller.EDIT.value)]);
    });

    test('callback failures propagate and stop later operations', () {
      final cases = <({String stage, List<String> reached})>[
        (stage: 'create', reached: ['create']),
        (stage: 'caller', reached: ['create', 'caller']),
        (stage: 'card', reached: ['create', 'caller', 'card']),
        (stage: 'cardIds', reached: ['create', 'caller', 'card', 'cardIds']),
        (
          stage: 'animation',
          reached: ['create', 'caller', 'card', 'cardIds', 'animation'],
        ),
        (
          stage: 'browser',
          reached: [
            'create',
            'caller',
            'card',
            'cardIds',
            'animation',
            'browser',
          ],
        ),
      ];

      for (final testCase in cases) {
        final failure = StateError('${testCase.stage} failed');
        final reached = <String>[];
        void invoke(String stage) {
          reached.add(stage);
          if (stage == testCase.stage) throw failure;
        }

        expect(
          () => noteEditorEditSelectionToIntent(
            context: Object(),
            cardIds: [42, 43],
            animation: Object(),
            inCardBrowserActivity: true,
            callbacks:
                NoteEditorEditSelectionIntentCallbacks<Object, Object, Object>(
                  createIntent: (_) {
                    invoke('create');
                    return Object();
                  },
                  putIntExtra: (_, key, value) => invoke('caller'),
                  putLongExtra: (_, key, value) => invoke('card'),
                  putLongArrayExtra: (_, key, value) => invoke('cardIds'),
                  putParcelableExtra: (_, key, value) => invoke('animation'),
                  putBooleanExtra: (_, key, value) => invoke('browser'),
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
