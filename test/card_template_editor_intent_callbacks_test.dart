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
  group('createCardTemplateEditorIntent', () {
    test(
      'constructs, writes source-ordered extras, logs, and returns identity',
      () {
        final intent = Object();
        final noteTypeId = Object();
        final noteId = Object();
        final ord = Object();
        final events = <Object?>[];
        final result = createCardTemplateEditorIntent(
          noteTypeId: noteTypeId,
          noteId: noteId,
          ord: ord,
          noteTypeIdKey: 'note-type-id',
          noteIdKey: 'note-id',
          ordKey: 'start-ord',
          callbacks:
              CardTemplateEditorIntentCallbacks<Object, Object, Object, Object>(
                createIntent: () {
                  events.add(('create',));
                  return intent;
                },
                putNoteTypeId: (target, key, value) {
                  events.add(('noteTypeId', target, key, value));
                },
                putNoteId: (target, key, value) {
                  events.add(('noteId', target, key, value));
                },
                putOrd: (target, key, value) {
                  events.add(('ord', target, key, value));
                },
                log: (loggedNoteTypeId, loggedNoteId, loggedOrd) {
                  events.add((
                    'log',
                    loggedNoteTypeId,
                    loggedNoteId,
                    loggedOrd,
                  ));
                },
              ),
        );

        expect(result, same(intent));
        expect(events, [
          ('create',),
          ('noteTypeId', intent, 'note-type-id', noteTypeId),
          ('noteId', intent, 'note-id', noteId),
          ('ord', intent, 'start-ord', ord),
          ('log', noteTypeId, noteId, ord),
        ]);
      },
    );

    test('skips both nullable writes when their values are null', () {
      final intent = Object();
      final events = <String>[];
      final result = createCardTemplateEditorIntent(
        noteTypeId: Object(),
        noteId: null,
        ord: null,
        noteTypeIdKey: 'note-type-id',
        noteIdKey: 'note-id',
        ordKey: 'start-ord',
        callbacks:
            CardTemplateEditorIntentCallbacks<Object, Object, Object, Object>(
              createIntent: () {
                events.add('create');
                return intent;
              },
              putNoteTypeId: (target, key, value) => events.add('noteTypeId'),
              putNoteId: (target, key, value) => events.add('noteId'),
              putOrd: (target, key, value) => events.add('ord'),
              log: (noteTypeId, noteId, ord) => events.add('log:$noteId:$ord'),
            ),
      );

      expect(result, same(intent));
      expect(events, ['create', 'noteTypeId', 'log:null:null']);
    });

    test(
      'skips each absent optional write while preserving the remaining order',
      () {
        for (final absent in ['noteId', 'ord']) {
          final intent = Object();
          final noteId = absent == 'noteId' ? null : Object();
          final ord = absent == 'ord' ? null : Object();
          final events = <String>[];
          createCardTemplateEditorIntent(
            noteTypeId: Object(),
            noteId: noteId,
            ord: ord,
            noteTypeIdKey: 'note-type-id',
            noteIdKey: 'note-id',
            ordKey: 'start-ord',
            callbacks:
                CardTemplateEditorIntentCallbacks<
                  Object,
                  Object,
                  Object,
                  Object
                >(
                  createIntent: () {
                    events.add('create');
                    return intent;
                  },
                  putNoteTypeId: (target, key, value) =>
                      events.add('noteTypeId'),
                  putNoteId: (target, key, value) => events.add('noteId'),
                  putOrd: (target, key, value) => events.add('ord'),
                  log: (noteTypeId, loggedNoteId, loggedOrd) =>
                      events.add('log'),
                ),
          );

          expect(events, [
            'create',
            'noteTypeId',
            if (noteId != null) 'noteId',
            if (ord != null) 'ord',
            'log',
          ], reason: '$absent omitted');
        }
      },
    );

    test('propagates callback failures and stops later actions', () {
      final cases = <({String stage, List<String> reached})>[
        (stage: 'create', reached: ['create']),
        (stage: 'noteTypeId', reached: ['create', 'noteTypeId']),
        (stage: 'noteId', reached: ['create', 'noteTypeId', 'noteId']),
        (stage: 'ord', reached: ['create', 'noteTypeId', 'noteId', 'ord']),
        (
          stage: 'log',
          reached: ['create', 'noteTypeId', 'noteId', 'ord', 'log'],
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
          () => createCardTemplateEditorIntent(
            noteTypeId: Object(),
            noteId: Object(),
            ord: Object(),
            noteTypeIdKey: 'note-type-id',
            noteIdKey: 'note-id',
            ordKey: 'start-ord',
            callbacks:
                CardTemplateEditorIntentCallbacks<
                  Object,
                  Object,
                  Object,
                  Object
                >(
                  createIntent: () {
                    invoke('create');
                    return Object();
                  },
                  putNoteTypeId: (target, key, value) => invoke('noteTypeId'),
                  putNoteId: (target, key, value) => invoke('noteId'),
                  putOrd: (target, key, value) => invoke('ord'),
                  log: (noteTypeId, noteId, ord) => invoke('log'),
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
