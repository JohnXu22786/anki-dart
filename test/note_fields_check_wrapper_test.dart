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
 * Source-derived adapter contract tests for Note.fieldsCheck; see
 * ANKIIDROID_UPSTREAM.md for the integration-test distinction.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('LibAnki Note.fieldsCheck wrapper', () {
    test('projects once, forwards the exact note, and returns exact state', () {
      final backendNote = _BackendNote();
      final response = _Response();
      final state = Object();
      final calls = <String>[];

      final result = libankiNoteFieldsCheck<_BackendNote, _Response, Object>(
        toBackendNote: () {
          calls.add('toBackendNote');
          return backendNote;
        },
        noteFieldsCheck: (note) {
          calls.add('noteFieldsCheck');
          expect(identical(note, backendNote), isTrue);
          return response;
        },
        responseState: (receivedResponse) {
          calls.add('state');
          expect(identical(receivedResponse, response), isTrue);
          return state;
        },
      );

      expect(calls, ['toBackendNote', 'noteFieldsCheck', 'state']);
      expect(identical(result, state), isTrue);
    });

    test(
      'propagates projection failure and skips backend and state access',
      () {
        final failure = StateError('projection failed');
        var backendCalls = 0;
        var stateCalls = 0;

        expect(
          () => libankiNoteFieldsCheck<Object, Object, Object>(
            toBackendNote: () => throw failure,
            noteFieldsCheck: (_) {
              backendCalls++;
              return Object();
            },
            responseState: (_) {
              stateCalls++;
              return Object();
            },
          ),
          throwsA(same(failure)),
        );
        expect(backendCalls, 0);
        expect(stateCalls, 0);
      },
    );

    test('propagates backend failure and skips state access', () {
      final failure = StateError('backend failed');
      final backendNote = Object();
      var stateCalls = 0;

      expect(
        () => libankiNoteFieldsCheck<Object, Object, Object>(
          toBackendNote: () => backendNote,
          noteFieldsCheck: (note) {
            expect(identical(note, backendNote), isTrue);
            throw failure;
          },
          responseState: (_) {
            stateCalls++;
            return Object();
          },
        ),
        throwsA(same(failure)),
      );
      expect(stateCalls, 0);
    });

    test('propagates state access failure unchanged', () {
      final failure = StateError('state access failed');
      final backendNote = Object();
      final response = Object();

      expect(
        () => libankiNoteFieldsCheck<Object, Object, Object>(
          toBackendNote: () => backendNote,
          noteFieldsCheck: (note) {
            expect(identical(note, backendNote), isTrue);
            return response;
          },
          responseState: (receivedResponse) {
            expect(identical(receivedResponse, response), isTrue);
            throw failure;
          },
        ),
        throwsA(same(failure)),
      );
    });
  });
}

final class _BackendNote {}

final class _Response {}
