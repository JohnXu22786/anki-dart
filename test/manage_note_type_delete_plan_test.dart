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
 * Source-derived cases for ManageNoteTypesViewModel.delete(); see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Manage Note Type single deletion plan', () {
    test(
      'the last note type still enters undoable operation and is retained',
      () async {
        final last = _row(7, 'last');
        final defaultResult = Object();
        var current = ManageNoteTypesState(
          isLoading: false,
          noteTypes: [last],
          error: 'existing error',
          message: 'old message',
          isInMultiSelectMode: true,
        );
        final events = <String>[];
        var safeRemoveCalls = 0;
        final plan = _prepare(
          7,
          readState: () {
            events.add('read count');
            return current;
          },
          updateState: (update) {
            events.add('publish');
            current = update(current);
          },
        );

        final result = await plan.run(
          undoableOp: (operation) {
            events.add('undoable');
            return operation();
          },
          safeRemove: (_) async {
            safeRemoveCalls++;
            return const ManageNoteTypeDeleteSuccess('unexpected');
          },
          defaultResult: () => defaultResult,
          reportError: (error) => error,
          deletingLastMessage: 'DeletingLastModel',
        );

        expect(events, ['publish', 'read count', 'undoable', 'publish']);
        expect(result, same(defaultResult));
        expect(safeRemoveCalls, 0);
        expect(current.isLoading, isFalse);
        expect(current.noteTypes, [last]);
        expect(current.message, 'DeletingLastModel');
        expect(current.error, 'existing error');
        expect(current.isInMultiSelectMode, isTrue);
      },
    );

    test('captures count immediately after loading publication', () async {
      final original = _row(1, 'one');
      var current = ManageNoteTypesState(noteTypes: [original]);
      final defaultResult = Object();
      final plan = _prepare(
        99,
        readState: () => current,
        updateState: (update) => current = update(current),
      );
      current = _copyWithRows(current, [original, _row(2, 'later row')]);
      var removeCalls = 0;

      final result = await plan.run(
        undoableOp: (operation) => operation(),
        safeRemove: (_) async {
          removeCalls++;
          return const ManageNoteTypeDeleteSuccess('changes');
        },
        defaultResult: () => defaultResult,
        reportError: (error) => error,
        deletingLastMessage: 'last',
      );

      expect(result, same(defaultResult));
      expect(removeCalls, 0);
      expect(current.noteTypes, hasLength(2));
      expect(current.message, 'last');
    });

    test(
      'removes all matching latest rows once and returns the success result',
      () async {
        final duplicateA = _row(5, 'duplicate A', selected: true);
        final keep = _row(8, 'keep');
        final duplicateB = _row(5, 'duplicate B');
        var current = ManageNoteTypesState(
          noteTypes: [duplicateA, keep, duplicateB],
          searchQuery: 'query',
          destination: const ManageNoteTypesCardEditor(44),
          message: 'keep message',
          error: 'keep error',
          isInMultiSelectMode: true,
        );
        final newRow = _row(9, 'new row', selected: false, displayed: false);
        final changes = Object();
        final defaultResult = Object();
        var removeCalls = 0;
        var receivedId = -1;
        final plan = _prepare(
          5,
          readState: () => current,
          updateState: (update) => current = update(current),
        );

        final result = await plan.run(
          undoableOp: (operation) => operation(),
          safeRemove: (id) async {
            removeCalls++;
            receivedId = id;
            current = _copyWithRows(current, [...current.noteTypes, newRow]);
            return ManageNoteTypeDeleteSuccess(changes);
          },
          defaultResult: () => defaultResult,
          reportError: (error) => error,
          deletingLastMessage: 'last',
        );

        expect(removeCalls, 1);
        expect(receivedId, 5);
        expect(result, same(changes));
        expect(result, isNot(same(defaultResult)));
        expect(current.noteTypes.map((row) => row.id), [8, 9]);
        expect(current.noteTypes.last, same(newRow));
        expect(current.isInMultiSelectMode, isFalse);
        expect(current.isLoading, isFalse);
        expect(current.searchQuery, 'query');
        expect(current.destination, const ManageNoteTypesCardEditor(44));
        expect(current.message, 'keep message');
        expect(current.error, 'keep error');
      },
    );

    test(
      'safe-remove failure wraps error and retains latest rows and mode',
      () async {
        final selected = _row(5, 'selected', selected: true);
        final other = _row(8, 'other');
        var current = ManageNoteTypesState(
          noteTypes: [selected, other],
          searchQuery: 'query',
          destination: const ManageNoteTypesCardEditor(44),
          message: 'keep message',
          error: 'old error',
          isInMultiSelectMode: true,
        );
        final latest = _row(9, 'arrived', displayed: false);
        final failure = StateError('blocked');
        final defaultResult = Object();
        Object? reported;
        final plan = _prepare(
          5,
          readState: () => current,
          updateState: (update) => current = update(current),
        );

        final result = await plan.run(
          undoableOp: (operation) => operation(),
          safeRemove: (_) async {
            current = _copyWithRows(current, [...current.noteTypes, latest]);
            return ManageNoteTypeDeleteFailure(failure);
          },
          defaultResult: () => defaultResult,
          reportError: (error) {
            reported = error;
            return ('reported', error);
          },
          deletingLastMessage: 'last',
        );

        expect(result, same(defaultResult));
        expect(reported, same(failure));
        expect(current.noteTypes, [selected, other, latest]);
        expect(current.isInMultiSelectMode, isTrue);
        expect(current.isLoading, isFalse);
        final reportedError = current.error! as (String, Object);
        expect(reportedError.$1, 'reported');
        expect(reportedError.$2, same(failure));
        expect(current.searchQuery, 'query');
        expect(current.destination, const ManageNoteTypesCardEditor(44));
        expect(current.message, 'keep message');
      },
    );

    test('host callback errors propagate at their source stage', () async {
      final selected = _row(5, 'selected');
      final initial = ManageNoteTypesState(
        noteTypes: [selected, _row(8, 'other')],
      );
      var current = initial;
      var publications = 0;
      final plan = _prepare(
        5,
        readState: () => current,
        updateState: (update) {
          current = update(current);
          publications++;
        },
      );
      final undoableError = StateError('undoable failed');
      await expectLater(
        plan.run(
          undoableOp: (_) => throw undoableError,
          safeRemove: (_) async => const ManageNoteTypeDeleteSuccess('unused'),
          defaultResult: () => Object(),
          reportError: (error) => error,
          deletingLastMessage: 'last',
        ),
        throwsA(same(undoableError)),
      );
      expect(publications, 1);
      expect(current.isLoading, isTrue);

      current = initial;
      publications = 0;
      final removePlan = _prepare(
        5,
        readState: () => current,
        updateState: (update) {
          current = update(current);
          publications++;
        },
      );
      final removeError = StateError('safe-remove callback threw');
      await expectLater(
        removePlan.run(
          undoableOp: (operation) => operation(),
          safeRemove: (_) async => throw removeError,
          defaultResult: () => Object(),
          reportError: (error) => error,
          deletingLastMessage: 'last',
        ),
        throwsA(same(removeError)),
      );
      expect(publications, 1);
      expect(current.isLoading, isTrue);

      current = initial;
      publications = 0;
      final wrapperPlan = _prepare(
        5,
        readState: () => current,
        updateState: (update) {
          current = update(current);
          publications++;
        },
      );
      final wrapperError = StateError('wrapper threw');
      await expectLater(
        wrapperPlan.run(
          undoableOp: (operation) => operation(),
          safeRemove: (_) async => ManageNoteTypeDeleteFailure(removeError),
          defaultResult: () => Object(),
          reportError: (_) => throw wrapperError,
          deletingLastMessage: 'last',
        ),
        throwsA(same(wrapperError)),
      );
      expect(publications, 1);
      expect(current.isLoading, isTrue);
      expect(current.error, isNull);
    });
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
) => state.copyWith(noteTypes: rows);

ManageNoteTypeDeletePlan<T> _prepare<T>(
  int noteTypeId, {
  required ManageNoteTypesState Function() readState,
  required void Function(ManageNoteTypesState Function(ManageNoteTypesState))
  updateState,
}) => prepareManageNoteTypeDelete(
  noteTypeId: noteTypeId,
  readState: readState,
  updateState: updateState,
);
