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
  group('noteEditorPassArgumentsFromIntent', () {
    test('retains the same extras and a null action', () {
      final intent = Object();
      final extras = Object();
      final projection = noteEditorPassArgumentsFromIntent(
        intent: intent,
        extras: extras,
        actionOf: (_) => null,
      );

      expect(projection.arguments, same(extras));
      expect(projection.action, isNull);
    });

    test('retains the exact action and extras token', () {
      final intent = Object();
      final extras = Object();
      const action = 'com.example.FORWARD';
      final projection = noteEditorPassArgumentsFromIntent(
        intent: intent,
        extras: extras,
        actionOf: (_) => action,
      );

      expect(projection.arguments, same(extras));
      expect(projection.action, action);
    });

    test('reads action once from the supplied Intent', () {
      final intent = Object();
      final extras = Object();
      var actionReads = 0;

      final projection = noteEditorPassArgumentsFromIntent(
        intent: intent,
        extras: extras,
        actionOf: (actualIntent) {
          expect(actualIntent, same(intent));
          actionReads++;
          return 'com.example.FORWARD';
        },
      );

      expect(actionReads, 1);
      expect(projection.arguments, same(extras));
    });

    test('propagates action getter failures unchanged', () {
      final failure = StateError('action unavailable');

      expect(
        () => noteEditorPassArgumentsFromIntent(
          intent: Object(),
          extras: Object(),
          actionOf: (_) => throw failure,
        ),
        throwsA(same(failure)),
      );
    });
  });
}
