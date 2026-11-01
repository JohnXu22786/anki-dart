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
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
 * more details.
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
  group('noteEditorAddNoteFromCardBrowserToIntent', () {
    test('writes extras in source order and returns the same intent', () {
      final context = Object();
      final intent = Object();
      final events = <Object?>[];

      final result = noteEditorAddNoteFromCardBrowserToIntent(
        context: context,
        searchTerms: 'tag:marked',
        deckId: 17,
        callbacks:
            NoteEditorAddNoteFromCardBrowserIntentCallbacks<
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
          putStringExtra: (target, key, value) {
            events.add(('string', target, key, value));
          },
          putBooleanExtra: (target, key, value) {
            events.add(('boolean', target, key, value));
          },
          putLongExtra: (target, key, value) {
            events.add(('long', target, key, value));
          },
        ),
      );

      expect(result, same(intent));
      expect(events, [
        ('create', context),
        ('int', intent, 'CALLER', NoteEditorCaller.CARDBROWSER_ADD.value),
        ('string', intent, 'SEARCH', 'tag:marked'),
        ('boolean', intent, 'inCardBrowserActivity', false),
        ('long', intent, 'DECK_ID', 17),
      ]);
    });

    test('passes empty search terms unchanged', () {
      final intent = Object();
      final events = <Object?>[];

      noteEditorAddNoteFromCardBrowserToIntent(
        context: Object(),
        searchTerms: '',
        deckId: null,
        callbacks:
            NoteEditorAddNoteFromCardBrowserIntentCallbacks<
              Object,
              Object
            >(
          createIntent: (_) => intent,
          putIntExtra: (target, key, value) {
            events.add(('int', key, value));
          },
          putStringExtra: (target, key, value) {
            events.add(('string', key, value));
          },
          putBooleanExtra: (target, key, value) {
            events.add(('boolean', key, value));
          },
          putLongExtra: (target, key, value) {
            events.add(('long', key, value));
          },
        ),
      );

      expect(events, [
        ('int', 'CALLER', NoteEditorCaller.CARDBROWSER_ADD.value),
        ('string', 'SEARCH', ''),
        ('boolean', 'inCardBrowserActivity', false),
      ]);
    });

    test('writes a deck ID only when it is positive', () {
      for (final deckId in <int?>[null, 0, -1, -100, 1, 2]) {
        final events = <Object?>[];
        noteEditorAddNoteFromCardBrowserToIntent(
          context: Object(),
          searchTerms: 'query',
          deckId: deckId,
          callbacks:
              NoteEditorAddNoteFromCardBrowserIntentCallbacks<Object, Object>(
                createIntent: (_) => Object(),
                putIntExtra: (target, key, value) {},
                putStringExtra: (target, key, value) {},
                putBooleanExtra: (target, key, value) {},
                putLongExtra: (target, key, value) {
                  events.add((key, value));
                },
              ),
        );

        expect(
          events,
          deckId != null && deckId > 0 ? [('DECK_ID', deckId)] : isEmpty,
          reason: 'deckId=$deckId',
        );
      }
    });

    test('propagates callback failures and stops later operations', () {
      final cases = <({String stage, List<String> reached})>[
        (stage: 'create', reached: ['create']),
        (stage: 'caller', reached: ['create', 'caller']),
        (stage: 'search', reached: ['create', 'caller', 'search']),
        (
          stage: 'browser',
          reached: ['create', 'caller', 'search', 'browser'],
        ),
        (
          stage: 'deck',
          reached: ['create', 'caller', 'search', 'browser', 'deck'],
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
          () => noteEditorAddNoteFromCardBrowserToIntent(
            context: Object(),
            searchTerms: 'query',
            deckId: 9,
            callbacks:
                NoteEditorAddNoteFromCardBrowserIntentCallbacks<Object, Object>(
                  createIntent: (_) {
                    invoke('create');
                    return Object();
                  },
                  putIntExtra: (target, key, value) => invoke('caller'),
                  putStringExtra: (target, key, value) => invoke('search'),
                  putBooleanExtra: (target, key, value) => invoke('browser'),
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
