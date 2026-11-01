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
  group('noteEditorAddInstantNoteToIntent', () {
    test('writes caller then exact text and returns the same intent', () {
      final context = Object();
      final intent = Object();
      final events = <Object?>[];

      final result = noteEditorAddInstantNoteToIntent(
        context: context,
        sharedText: 'shared note',
        callbacks: NoteEditorAddInstantNoteIntentCallbacks<Object, Object>(
          createIntent: (actualContext) {
            events.add(('create', actualContext));
            return intent;
          },
          putIntExtra: (target, key, value) {
            events.add(('int', target, key, value));
          },
          putStringExtra: (target, key, value) {
            events.add(('string', target, key, value));
          },
        ),
      );

      expect(result, same(intent));
      expect(events, [
        ('create', context),
        ('int', intent, 'CALLER', 14),
        ('string', intent, 'android.intent.extra.TEXT', 'shared note'),
      ]);
    });

    test('writes empty shared text instead of omitting the extra', () {
      final intent = Object();
      final writes = <(String, Object, String, Object)>[];

      noteEditorAddInstantNoteToIntent(
        context: Object(),
        sharedText: '',
        callbacks: NoteEditorAddInstantNoteIntentCallbacks<Object, Object>(
          createIntent: (_) => intent,
          putIntExtra: (target, key, value) {
            writes.add(('int', target, key, value));
          },
          putStringExtra: (target, key, value) {
            writes.add(('string', target, key, value));
          },
        ),
      );

      expect(writes, [
        ('int', intent, 'CALLER', 14),
        ('string', intent, 'android.intent.extra.TEXT', ''),
      ]);
    });

    test('propagates callback failures and stops later operations', () {
      final cases = <({String stage, List<String> reached})>[
        (stage: 'create', reached: ['create']),
        (stage: 'caller', reached: ['create', 'caller']),
        (stage: 'text', reached: ['create', 'caller', 'text']),
      ];

      for (final testCase in cases) {
        final failure = StateError('${testCase.stage} failed');
        final reached = <String>[];
        void invoke(String stage) {
          reached.add(stage);
          if (stage == testCase.stage) throw failure;
        }

        expect(
          () => noteEditorAddInstantNoteToIntent(
            context: Object(),
            sharedText: 'text',
            callbacks: NoteEditorAddInstantNoteIntentCallbacks<Object, Object>(
              createIntent: (_) {
                invoke('create');
                return Object();
              },
              putIntExtra: (target, key, value) => invoke('caller'),
              putStringExtra: (target, key, value) => invoke('text'),
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
