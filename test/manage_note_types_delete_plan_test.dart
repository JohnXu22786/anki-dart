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
 * Source-derived cases for ManageNoteTypesViewModel.deleteSelectedNoteTypes();
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Manage Note Types selected deletion plan', () {
    test(
      'no selection clears loading and a previous error without removals',
      () async {
        final rows = [_row(1, 'one'), _row(2, 'two')];
        final priorError = Object();
        var current = ManageNoteTypesState(
          isLoading: false,
          noteTypes: rows,
          error: priorError,
          message: 'keep message',
          searchQuery: 'query',
        );
        var removeCount = 0;
        final plan = _prepare(
          current,
          updateState: (update) => current = update(current),
          remove: (_) async {
            removeCount++;
            return const ManageNoteTypeRemovalSuccess('changes');
          },
          combineErrors: (errors) {
            expect(errors, isEmpty);
            return null;
          },
        );

        expect(plan.selectedRows, isEmpty);
        expect(current.isLoading, isTrue);
        expect(current.noteTypes.every((row) => !row.isSelected), isTrue);
        await plan.run(readState: () => current);

        expect(removeCount, 0);
        expect(current.isLoading, isFalse);
        expect(current.noteTypes.map((row) => row.id), [1, 2]);
        expect(current.noteTypes.every((row) => !row.isSelected), isTrue);
        expect(current.error, isNull);
        expect(current.message, 'keep message');
        expect(current.searchQuery, 'query');
      },
    );

    test(
      'snapshots selected rows in list order and clears selection before removal',
      () async {
        final first = _row(2, 'first', selected: true, displayed: false);
        final middle = _row(8, 'middle');
        final last = _row(1, 'last', selected: true);
        var current = ManageNoteTypesState(
          isLoading: false,
          noteTypes: [first, middle, last],
          isInMultiSelectMode: true,
        );
        final events = <String>[];
        final receivedRows = <NoteTypeItemState>[];
        final plan = _prepare(
          current,
          updateState: (update) {
            current = update(current);
            events.add('state update');
          },
          remove: (row) async {
            events.add('remove ${row.id}');
            receivedRows.add(row);
            expect(current.isLoading, isTrue);
            expect(current.isInMultiSelectMode, isFalse);
            expect(current.noteTypes.every((item) => !item.isSelected), isTrue);
            return ManageNoteTypeRemovalSuccess(row.id);
          },
          combineErrors: (_) => null,
        );

        expect(plan.selectedRows, [first, last]);
        expect(() => plan.selectedRows.clear(), throwsUnsupportedError);
        expect(current.noteTypes[0].shouldBeDisplayed, isFalse);
        expect(current.noteTypes.map((row) => row.isSelected), [
          false,
          false,
          false,
        ]);
        await plan.run(readState: () => current);

        expect(receivedRows, [first, last]);
        expect(receivedRows[0].isSelected, isTrue);
        expect(receivedRows[0].shouldBeDisplayed, isFalse);
        expect(events, [
          'state update',
          'remove 2',
          'remove 1',
          'state update',
        ]);
      },
    );

    test(
      'continues after failures and filters the latest rows by successful IDs',
      () async {
        final selectedFailed = _row(1, 'failed', selected: true);
        final selectedSucceeded = _row(2, 'succeeded', selected: true);
        final selectedAlsoSucceeded = _row(3, 'also succeeded', selected: true);
        final initiallyUnselected = _row(4, 'unselected');
        var current = ManageNoteTypesState(
          noteTypes: [
            selectedFailed,
            selectedSucceeded,
            initiallyUnselected,
            selectedAlsoSucceeded,
          ],
          searchQuery: 'preserve this query',
          destination: const ManageNoteTypesCardEditor(44),
          message: 'preserve this message',
          isInMultiSelectMode: true,
        );
        final events = <String>[];
        final newRow = _row(9, 'arrived while deleting', displayed: false);
        final changedUnselected = initiallyUnselected.copyWith(
          shouldBeDisplayed: false,
        );
        final plan = _prepare(
          current,
          updateState: (update) {
            current = update(current);
            events.add('publish');
          },
          remove: (row) async {
            events.add('remove ${row.id}');
            if (row.id == 3) {
              current = _copyWithRows(current, [
                current.noteTypes[0],
                current.noteTypes[1],
                changedUnselected,
                current.noteTypes[3],
                newRow,
              ]);
            }
            if (row.id == 1) {
              return ManageNoteTypeRemovalFailure(StateError('blocked'));
            }
            return ManageNoteTypeRemovalSuccess(Object());
          },
          combineErrors: (_) => 'combined',
        );

        await plan.run(readState: () => current);

        expect(events, [
          'publish',
          'remove 1',
          'remove 2',
          'remove 3',
          'publish',
        ]);
        expect(current.noteTypes.map((row) => row.id), [1, 4, 9]);
        expect(current.noteTypes[1], same(changedUnselected));
        expect(current.noteTypes[2], same(newRow));
        expect(current.error, 'combined');
        expect(current.searchQuery, 'preserve this query');
        expect(current.destination, const ManageNoteTypesCardEditor(44));
        expect(current.message, 'preserve this message');
      },
    );

    test(
      'passes error labels and throwables in failure order and clears error on success',
      () async {
        final rows = [
          _row(4, 'four', selected: true),
          _row(2, 'two', selected: true),
          _row(9, 'nine', selected: true),
        ];
        final firstFailure = StateError('first failure');
        final secondFailure = ArgumentError('second failure');
        final errorInputs = <ManageNoteTypeDeletionError>[];
        var current = ManageNoteTypesState(noteTypes: rows, error: 'old error');
        final failedPlan = _prepare(
          current,
          updateState: (update) => current = update(current),
          remove: (row) async => switch (row.id) {
            4 => ManageNoteTypeRemovalFailure(firstFailure),
            2 => ManageNoteTypeRemovalSuccess('ok'),
            _ => ManageNoteTypeRemovalFailure(secondFailure),
          },
          combineErrors: (errors) {
            errorInputs.addAll(errors);
            return 'wrapped';
          },
        );

        await failedPlan.run(readState: () => current);
        expect(errorInputs.map((error) => error.label), [
          'four - Bad state: first failure',
          'nine - Invalid argument(s): second failure',
        ]);
        expect(errorInputs.map((error) => error.throwable), [
          firstFailure,
          secondFailure,
        ]);
        expect(current.noteTypes.map((row) => row.id), [4, 9]);
        expect(current.error, 'wrapped');

        current = ManageNoteTypesState(
          noteTypes: [_row(7, 'seven', selected: true)],
          error: 'stale',
        );
        final successfulPlan = _prepare(
          current,
          updateState: (update) => current = update(current),
          remove: (_) async => const ManageNoteTypeRemovalSuccess('changes'),
          combineErrors: (errors) {
            expect(errors, isEmpty);
            return null;
          },
        );
        await successfulPlan.run(readState: () => current);
        expect(current.noteTypes, isEmpty);
        expect(current.error, isNull);
      },
    );

    test(
      'equal row failures coalesce like source data-class map keys',
      () async {
        final firstEqualRow = _row(4, 'four', selected: true);
        final secondEqualRow = _row(4, 'four', selected: true);
        final followingRow = _row(2, 'two', selected: true);
        final firstFailure = StateError('first');
        final replacementFailure = StateError('replacement');
        final inputs = <ManageNoteTypeDeletionError>[];
        var current = ManageNoteTypesState(
          noteTypes: [firstEqualRow, secondEqualRow, followingRow],
        );
        final plan = _prepare(
          current,
          updateState: (update) => current = update(current),
          remove: (row) async => ManageNoteTypeRemovalFailure(
            row.id == 4
                ? (identical(row, firstEqualRow)
                      ? firstFailure
                      : replacementFailure)
                : StateError('following'),
          ),
          combineErrors: (errors) {
            inputs.addAll(errors);
            return 'combined';
          },
        );

        await plan.run(readState: () => current);

        expect(inputs.map((error) => error.label), [
          'four - Bad state: replacement',
          'two - Bad state: following',
        ]);
        expect(inputs.first.throwable, same(replacementFailure));
        expect(current.noteTypes.map((row) => row.id), [4, 4, 2]);
      },
    );

    test(
      'a removal callback failure escapes and skips final publication',
      () async {
        var current = ManageNoteTypesState(
          noteTypes: [_row(1, 'one', selected: true), _row(2, 'two')],
        );
        var publishes = 0;
        final plan = _prepare(
          current,
          updateState: (update) {
            current = update(current);
            publishes++;
          },
          remove: (_) async => throw StateError('undoable callback failed'),
          combineErrors: (_) => null,
        );

        await expectLater(plan.run(readState: () => current), throwsStateError);
        expect(publishes, 1);
        expect(current.isLoading, isTrue);
        expect(current.noteTypes.every((row) => !row.isSelected), isTrue);
      },
    );

    test(
      'an error-combination callback failure escapes before final publication',
      () async {
        var current = ManageNoteTypesState(
          noteTypes: [_row(1, 'one', selected: true)],
        );
        var publishes = 0;
        final plan = _prepare(
          current,
          updateState: (update) {
            current = update(current);
            publishes++;
          },
          remove: (_) async =>
              ManageNoteTypeRemovalFailure(StateError('safe remove failed')),
          combineErrors: (_) => throw StateError('host wrapper failed'),
        );

        await expectLater(plan.run(readState: () => current), throwsStateError);
        expect(publishes, 1);
        expect(current.isLoading, isTrue);
        expect(current.noteTypes.single.isSelected, isFalse);
      },
    );
  });
}

NoteTypeItemState _row(
  int id,
  String name, {
  bool selected = false,
  bool displayed = true,
}) => NoteTypeItemState(
  id: id,
  name: name,
  useCount: 1,
  isSelected: selected,
  shouldBeDisplayed: displayed,
);

ManageNoteTypesState _copyWithRows(
  ManageNoteTypesState state,
  List<NoteTypeItemState> rows,
) => ManageNoteTypesState(
  isLoading: state.isLoading,
  noteTypes: rows,
  searchQuery: state.searchQuery,
  destination: state.destination,
  error: state.error,
  message: state.message,
  isInMultiSelectMode: state.isInMultiSelectMode,
);

ManageNoteTypeDeletionPlan _prepare(
  ManageNoteTypesState initialState, {
  required void Function(ManageNoteTypesState Function(ManageNoteTypesState))
  updateState,
  required Future<ManageNoteTypeRemovalResult> Function(NoteTypeItemState)
  remove,
  required Object? Function(List<ManageNoteTypeDeletionError>) combineErrors,
}) => prepareManageNoteTypeDeletion(
  initialState: initialState,
  updateState: updateState,
  remove: remove,
  combineErrors: combineErrors,
);
