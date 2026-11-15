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
 * Source-derived from NoteEditorDestination.kt and NoteEditorTest.kt in
 * AnkiDroid 2.25.3; see ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('noteEditorAddNoteToIntent', () {
    test('creates once, writes caller only, and returns that intent', () {
      final context = Object();
      final intent = Object();
      final events = <Object?>[];

      final result = noteEditorAddNoteToIntent(
        context: context,
        deckId: null,
        callbacks: NoteEditorAddNoteIntentCallbacks<Object, Object>(
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
        ('int', intent, 'CALLER', NoteEditorCaller.DECKPICKER.value),
      ]);
    });

    test('writes every non-null deck ID unchanged after the caller', () {
      for (final deckId in [42, 0, -7]) {
        final intent = Object();
        final events = <Object?>[];
        final result = noteEditorAddNoteToIntent(
          context: Object(),
          deckId: deckId,
          callbacks: NoteEditorAddNoteIntentCallbacks<Object, Object>(
            createIntent: (_) => intent,
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
          ('int', intent, 'CALLER', NoteEditorCaller.DECKPICKER.value),
          ('long', intent, 'DECK_ID', deckId),
        ], reason: 'deck ID $deckId');
      }
    });

    test('propagates failures and stops later operations', () {
      final cases = <({String stage, List<String> reached})>[
        (stage: 'create', reached: ['create']),
        (stage: 'caller', reached: ['create', 'caller']),
        (stage: 'deck', reached: ['create', 'caller', 'deck']),
      ];

      for (final testCase in cases) {
        final failure = StateError('${testCase.stage} failed');
        final reached = <String>[];
        void invoke(String stage) {
          reached.add(stage);
          if (stage == testCase.stage) throw failure;
        }

        expect(
          () => noteEditorAddNoteToIntent(
            context: Object(),
            deckId: 5,
            callbacks: NoteEditorAddNoteIntentCallbacks<Object, Object>(
              createIntent: (_) {
                invoke('create');
                return Object();
              },
              putIntExtra: (target, key, value) => invoke('caller'),
              putLongExtra: (target, key, value) => invoke('deck'),
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
