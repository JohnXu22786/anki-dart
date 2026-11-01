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
 * Source-derived from NoteEditorFragment.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('noteEditorFragmentNewInstance', () {
    test(
      'creates once, assigns the exact arguments, and returns that fragment',
      () {
        final fragment = Object();
        final arguments = Object();
        final calls = <String>[];
        var createdFragment = Object();
        var createdArguments = Object();

        final result = noteEditorFragmentNewInstance(
          args: arguments,
          createFragment: () {
            calls.add('create');
            createdFragment = fragment;
            return fragment;
          },
          assignArguments: (candidateFragment, candidateArguments) {
            calls.add('assign');
            createdFragment = candidateFragment;
            createdArguments = candidateArguments;
          },
        );

        expect(calls, ['create', 'assign']);
        expect(identical(createdFragment, fragment), isTrue);
        expect(identical(createdArguments, arguments), isTrue);
        expect(identical(result, fragment), isTrue);
      },
    );

    test(
      'propagates fragment creation failure without assigning arguments',
      () {
        final failure = StateError('create failed');
        var assignmentCalls = 0;

        expect(
          () => noteEditorFragmentNewInstance(
            args: Object(),
            createFragment: () => throw failure,
            assignArguments: (_, _) => assignmentCalls++,
          ),
          throwsA(same(failure)),
        );
        expect(assignmentCalls, 0);
      },
    );

    test('propagates argument assignment failure unchanged', () {
      final failure = StateError('assignment failed');
      final fragment = Object();
      final arguments = Object();
      var creationCalls = 0;
      var assignmentCalls = 0;

      expect(
        () => noteEditorFragmentNewInstance(
          args: arguments,
          createFragment: () {
            creationCalls++;
            return fragment;
          },
          assignArguments: (candidateFragment, candidateArguments) {
            assignmentCalls++;
            expect(identical(candidateFragment, fragment), isTrue);
            expect(identical(candidateArguments, arguments), isTrue);
            throw failure;
          },
        ),
        throwsA(same(failure)),
      );
      expect(creationCalls, 1);
      expect(assignmentCalls, 1);
    });
  });
}
