/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 *
 * This file is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived cases for StudyOptionsViewModel.rebuildCram() and emptyCram();
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Study Options filtered-deck actions', () {
    test(
      'logs and awaits the selected scheduler action before collection refresh',
      () async {
        for (final action in _Action.values) {
          final calls = <String>[];
          final selected = <int>[3, 8];
          List<int>? forwarded;
          final operations = _operations(
            calls,
            selected: selected,
            onScheduler: (decks) => forwarded = decks,
          );

          await _run(operations, action);

          expect(calls, [
            action.diagnostic,
            'undoable start',
            'selected decks',
            action.schedulerCall,
            'undoable complete',
            'withCol start',
            'refresh',
            'withCol complete',
          ]);
          expect(identical(forwarded, selected), isTrue);
        }
      },
    );

    test(
      'scheduler failures propagate unchanged and skip collection refresh',
      () async {
        for (final action in _Action.values) {
          final calls = <String>[];
          final failure = StateError('scheduler failed');
          final operations = _operations(calls, schedulerFailure: failure);

          await expectLater(_run(operations, action), throwsA(same(failure)));
          expect(calls, [
            action.diagnostic,
            'undoable start',
            'selected decks',
            action.schedulerCall,
          ]);
        }
      },
    );

    test(
      'refresh failures propagate unchanged after successful scheduler work',
      () async {
        for (final action in _Action.values) {
          final calls = <String>[];
          final failure = StateError('refresh failed');
          final operations = _operations(calls, refreshFailure: failure);

          await expectLater(_run(operations, action), throwsA(same(failure)));
          expect(calls, [
            action.diagnostic,
            'undoable start',
            'selected decks',
            action.schedulerCall,
            'undoable complete',
            'withCol start',
            'refresh',
          ]);
        }
      },
    );
  });
}

enum _Action {
  rebuild('doInBackground - RebuildCram', 'rebuildFilteredDeck'),
  empty('doInBackgroundEmptyCram', 'emptyFilteredDeck');

  const _Action(this.diagnostic, this.schedulerCall);

  final String diagnostic;
  final String schedulerCall;
}

StudyOptionsFilteredDeckActions<List<int>> _operations(
  List<String> calls, {
  List<int> selected = const [3, 8],
  void Function(List<int>)? onScheduler,
  Object? schedulerFailure,
  Object? refreshFailure,
}) => StudyOptionsFilteredDeckActions(
  logDiagnostic: calls.add,
  selectedDecks: () {
    calls.add('selected decks');
    return selected;
  },
  undoableOp: (operation) async {
    calls.add('undoable start');
    await operation();
    calls.add('undoable complete');
  },
  rebuildFilteredDeck: (decks) async {
    calls.add('rebuildFilteredDeck');
    onScheduler?.call(decks);
    if (schedulerFailure != null) throw schedulerFailure;
  },
  emptyFilteredDeck: (decks) async {
    calls.add('emptyFilteredDeck');
    onScheduler?.call(decks);
    if (schedulerFailure != null) throw schedulerFailure;
  },
  withCol: (operation) async {
    calls.add('withCol start');
    await operation();
    calls.add('withCol complete');
  },
  updateStateFromCollection: () async {
    calls.add('refresh');
    if (refreshFailure != null) throw refreshFailure;
  },
);

Future<void> _run(
  StudyOptionsFilteredDeckActions<List<int>> operations,
  _Action action,
) => switch (action) {
  _Action.rebuild => operations.rebuildCram(),
  _Action.empty => operations.emptyCram(),
};
