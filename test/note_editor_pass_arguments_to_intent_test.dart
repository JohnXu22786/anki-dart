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
  group('noteEditorPassArgumentsToIntent', () {
    test(
      'creates once, forwards the same Bundle, sets the action, and returns the Intent',
      () {
        for (final action in <String?>['com.example.OPEN', null]) {
          final context = Object();
          final intent = Object();
          final arguments = Object();
          final events = <Object?>[];
          var forwardedArguments = Object();

          final result = noteEditorPassArgumentsToIntent(
            context: context,
            arguments: arguments,
            action: action,
            callbacks:
                NoteEditorPassArgumentsIntentCallbacks<Object, Object, Object>(
                  createIntent: (actualContext) {
                    events.add(('create', actualContext));
                    return intent;
                  },
                  putExtras: (target, bundle) {
                    forwardedArguments = bundle;
                    events.add(('extras', target, bundle));
                  },
                  setAction: (target, value) {
                    events.add(('action', target, value));
                  },
                ),
          );

          expect(result, same(intent));
          expect(forwardedArguments, same(arguments));
          expect(events, [
            ('create', context),
            ('extras', intent, arguments),
            ('action', intent, action),
          ], reason: 'action $action');
        }
      },
    );

    test('callback failures propagate unchanged and stop later operations', () {
      final cases = <({String stage, List<String> reached})>[
        (stage: 'create', reached: ['create']),
        (stage: 'extras', reached: ['create', 'extras']),
        (stage: 'action', reached: ['create', 'extras', 'action']),
      ];

      for (final testCase in cases) {
        final failure = StateError('${testCase.stage} failed');
        final reached = <String>[];
        void invoke(String stage) {
          reached.add(stage);
          if (stage == testCase.stage) throw failure;
        }

        expect(
          () => noteEditorPassArgumentsToIntent(
            context: Object(),
            arguments: Object(),
            action: 'com.example.OPEN',
            callbacks:
                NoteEditorPassArgumentsIntentCallbacks<Object, Object, Object>(
                  createIntent: (_) {
                    invoke('create');
                    return Object();
                  },
                  putExtras: (_, _) => invoke('extras'),
                  setAction: (_, _) => invoke('action'),
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
