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
 * Source-derived cases for StudyOptionsViewModel.unbury(); see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Study Options unbury callbacks', () {
    test('reads current deck inside one undoable unbury operation', () async {
      final calls = <String>[];
      var currentDeckId = 7;
      int? forwardedDeckId;
      final actions = StudyOptionsUnburyCallbacks<int>(
        currentDeckId: () {
          calls.add('current deck');
          return currentDeckId;
        },
        unburyDeck: (deckId) async {
          calls.add('unbury deck');
          forwardedDeckId = deckId;
        },
        undoableOp: (operation) async {
          calls.add('undoable start');
          currentDeckId = 42;
          await operation();
          calls.add('undoable complete');
        },
      );

      await actions.unbury();

      expect(calls, [
        'undoable start',
        'current deck',
        'unbury deck',
        'undoable complete',
      ]);
      expect(forwardedDeckId, 42);
    });

    test('callback failures propagate and stop later callbacks', () async {
      final lookupCalls = <String>[];
      final lookupFailure = StateError('deck lookup failed');
      final lookupActions = StudyOptionsUnburyCallbacks<int>(
        currentDeckId: () {
          lookupCalls.add('current deck');
          throw lookupFailure;
        },
        unburyDeck: (_) async => lookupCalls.add('unbury deck'),
        undoableOp: (operation) async {
          lookupCalls.add('undoable start');
          await operation();
          lookupCalls.add('undoable complete');
        },
      );
      await expectLater(lookupActions.unbury(), throwsA(same(lookupFailure)));
      expect(lookupCalls, ['undoable start', 'current deck']);

      final schedulerCalls = <String>[];
      final schedulerFailure = StateError('scheduler failed');
      final schedulerActions = StudyOptionsUnburyCallbacks<int>(
        currentDeckId: () {
          schedulerCalls.add('current deck');
          return 7;
        },
        unburyDeck: (_) async {
          schedulerCalls.add('unbury deck');
          throw schedulerFailure;
        },
        undoableOp: (operation) async {
          schedulerCalls.add('undoable start');
          await operation();
          schedulerCalls.add('undoable complete');
        },
      );
      await expectLater(
        schedulerActions.unbury(),
        throwsA(same(schedulerFailure)),
      );
      expect(schedulerCalls, ['undoable start', 'current deck', 'unbury deck']);

      final undoableCalls = <String>[];
      final undoableFailure = StateError('undoable operation failed');
      final undoableActions = StudyOptionsUnburyCallbacks<int>(
        currentDeckId: () {
          undoableCalls.add('current deck');
          return 7;
        },
        unburyDeck: (_) async => undoableCalls.add('unbury deck'),
        undoableOp: (_) async {
          undoableCalls.add('undoable operation');
          throw undoableFailure;
        },
      );
      await expectLater(
        undoableActions.unbury(),
        throwsA(same(undoableFailure)),
      );
      expect(undoableCalls, ['undoable operation']);
    });
  });
}
