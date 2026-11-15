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
  group('noteEditorCopyNoteToIntent', () {
    test('writes exact extras in source order and returns the same intent', () {
      final context = Object();
      final intent = Object();
      final tags = ['alpha', 'beta', 'alpha'];
      final events = <Object?>[];
      List<String>? writtenTags;

      final result = noteEditorCopyNoteToIntent(
        context: context,
        deckId: 42,
        fieldsText: 'Front\u001fBack',
        tags: tags,
        callbacks: NoteEditorCopyNoteIntentCallbacks<Object, Object>(
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
          putStringExtra: (target, key, value) {
            events.add(('string', target, key, value));
          },
          putStringArrayExtra: (target, key, value) {
            writtenTags = value;
            events.add(('stringArray', target, key, value.length));
          },
        ),
      );

      tags[0] = 'changed';
      expect(result, same(intent));
      expect(writtenTags, ['alpha', 'beta', 'alpha']);
      expect(writtenTags, isNot(same(tags)));
      expect(events, [
        ('create', context),
        ('int', intent, 'CALLER', NoteEditorCaller.NOTEEDITOR.value),
        ('long', intent, 'DECK_ID', 42),
        ('string', intent, 'CONTENTS', 'Front\u001fBack'),
        ('stringArray', intent, 'TAGS', 3),
      ]);
    });

    test('preserves empty fields and writes a fresh empty tag list', () {
      final intent = Object();
      final events = <Object?>[];
      List<String>? writtenTags;

      final result = noteEditorCopyNoteToIntent(
        context: Object(),
        deckId: 0,
        fieldsText: '',
        tags: const [],
        callbacks: NoteEditorCopyNoteIntentCallbacks<Object, Object>(
          createIntent: (_) => intent,
          putIntExtra: (target, key, value) => events.add(('int', key, value)),
          putLongExtra: (target, key, value) =>
              events.add(('long', key, value)),
          putStringExtra: (target, key, value) =>
              events.add(('string', key, value)),
          putStringArrayExtra: (target, key, value) {
            writtenTags = value;
            events.add(('stringArray', key, value.length));
          },
        ),
      );

      expect(result, same(intent));
      expect(events, [
        ('int', 'CALLER', NoteEditorCaller.NOTEEDITOR.value),
        ('long', 'DECK_ID', 0),
        ('string', 'CONTENTS', ''),
        ('stringArray', 'TAGS', 0),
      ]);
      expect(writtenTags, isEmpty);
      expect(writtenTags, isNot(same(const <String>[])));
    });

    test('callback failures propagate and stop later operations', () {
      final cases = <({String stage, List<String> reached})>[
        (stage: 'create', reached: ['create']),
        (stage: 'caller', reached: ['create', 'caller']),
        (stage: 'deck', reached: ['create', 'caller', 'deck']),
        (stage: 'contents', reached: ['create', 'caller', 'deck', 'contents']),
        (
          stage: 'tags',
          reached: ['create', 'caller', 'deck', 'contents', 'tags'],
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
          () => noteEditorCopyNoteToIntent(
            context: Object(),
            deckId: 5,
            fieldsText: 'fields',
            tags: ['tag'],
            callbacks: NoteEditorCopyNoteIntentCallbacks<Object, Object>(
              createIntent: (_) {
                invoke('create');
                return Object();
              },
              putIntExtra: (_, key, value) => invoke('caller'),
              putLongExtra: (_, key, value) => invoke('deck'),
              putStringExtra: (_, key, value) => invoke('contents'),
              putStringArrayExtra: (_, key, value) => invoke('tags'),
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
