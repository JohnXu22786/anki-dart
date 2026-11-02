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
 * Source-derived cases for ManageNoteTypesViewModel.rename(); see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Manage Note Type rename plan', () {
    test(
      'publishes loading then renames all matching latest rows by name only',
      () async {
        final duplicateA = _row(7, 'old A', selected: true, displayed: false);
        final keep = _row(8, 'keep', displayed: false);
        final duplicateB = _row(7, 'old B', displayed: false);
        final appended = _row(7, 'old C', selected: true, displayed: true);
        var current = ManageNoteTypesState(
          isLoading: false,
          noteTypes: [duplicateA, keep, duplicateB],
          searchQuery: 'old',
          destination: const ManageNoteTypesCardEditor(8),
          error: 'prior error',
          message: 'prior message',
          isInMultiSelectMode: true,
        );
        final events = <String>[];
        var forwardedId = -1;
        var forwardedName = '';
        final changes = Object();
        var safeRenameCalls = 0;
        final plan = prepareManageNoteTypeRename(
          noteTypeId: 7,
          name: 'renamed',
          updateState: (update) {
            events.add('publish');
            current = update(current);
          },
        );

        expect(current.isLoading, isTrue);
        final result = await plan.run<Object>(
          undoableOp: (operation) {
            events.add('undoable');
            expect(current.isLoading, isTrue);
            return operation();
          },
          safeRename: (id, name) async {
            events.add('safe rename');
            safeRenameCalls++;
            forwardedId = id;
            forwardedName = name;
            current = current.copyWith(
              noteTypes: [...current.noteTypes, appended],
            );
            return ManageNoteTypeRenameSuccess(changes);
          },
          defaultResult: () => Object(),
          reportError: (_, {required isReportable}) =>
              fail('unexpected report error'),
        );

        expect(events, ['publish', 'undoable', 'safe rename', 'publish']);
        expect(safeRenameCalls, 1);
        expect(forwardedId, 7);
        expect(forwardedName, 'renamed');
        expect(result, same(changes));
        expect(current.isLoading, isFalse);
        expect(current.noteTypes, hasLength(4));
        expect(current.noteTypes[0].name, 'renamed');
        expect(current.noteTypes[1], same(keep));
        expect(current.noteTypes[2].name, 'renamed');
        expect(current.noteTypes[3].name, 'renamed');
        expect(current.noteTypes.map((row) => row.shouldBeDisplayed), [
          false,
          false,
          false,
          true,
        ]);
        expect(current.noteTypes.map((row) => row.isSelected), [
          true,
          false,
          false,
          true,
        ]);
        expect(current.noteTypes.map((row) => row.useCount), [7, 8, 7, 7]);
        expect(current.searchQuery, 'old');
        expect(current.destination, const ManageNoteTypesCardEditor(8));
        expect(current.error, 'prior error');
        expect(current.message, 'prior message');
        expect(current.isInMultiSelectMode, isTrue);
      },
    );

    test(
      'safe-rename failure reports according to host backend classification',
      () async {
        for (final isBackendException in [true, false]) {
          final row = _row(7, 'old', selected: true, displayed: false);
          var current = ManageNoteTypesState(
            isLoading: false,
            noteTypes: [row],
            searchQuery: 'keep',
            error: 'prior error',
            message: 'prior message',
            isInMultiSelectMode: true,
          );
          final throwable = StateError('rename failed');
          final defaultResult = Object();
          Object? reportableError;
          bool? reportability;
          final plan = prepareManageNoteTypeRename(
            noteTypeId: 7,
            name: 'new',
            updateState: (update) => current = update(current),
          );

          final result = await plan.run<Object>(
            undoableOp: (operation) => operation(),
            safeRename: (_, _) async =>
                ManageNoteTypeRenameFailure(throwable, isBackendException),
            defaultResult: () => defaultResult,
            reportError: (error, {required isReportable}) {
              reportableError = error;
              reportability = isReportable;
              return 'host reportable error';
            },
          );

          expect(result, same(defaultResult));
          expect(reportableError, same(throwable));
          expect(reportability, !isBackendException);
          expect(current.isLoading, isFalse);
          expect(current.noteTypes, [row]);
          expect(current.searchQuery, 'keep');
          expect(current.error, 'host reportable error');
          expect(current.message, 'prior message');
          expect(current.isInMultiSelectMode, isTrue);
        }
      },
    );

    test(
      'safe-rename callback exceptions propagate before state publication',
      () async {
        final state = ManageNoteTypesState(
          isLoading: false,
          noteTypes: [_row(7, 'old')],
        );
        var current = state;
        final callbackError = StateError('safe rename callback failed');
        final events = <String>[];
        final plan = prepareManageNoteTypeRename(
          noteTypeId: 7,
          name: 'new',
          updateState: (update) {
            events.add('publish');
            current = update(current);
          },
        );

        await expectLater(
          plan.run<Object>(
            undoableOp: (operation) {
              events.add('undoable');
              return operation();
            },
            safeRename: (_, _) async {
              events.add('safe rename');
              throw callbackError;
            },
            defaultResult: () {
              events.add('default result');
              return Object();
            },
            reportError: (_, {required isReportable}) {
              events.add('report error');
              return Object();
            },
          ),
          throwsA(same(callbackError)),
        );

        expect(events, ['publish', 'undoable', 'safe rename']);
        expect(current, isNot(same(state)));
        expect(current.isLoading, isTrue);
        expect(current.noteTypes, same(state.noteTypes));
      },
    );

    test(
      'report-error callback exceptions stop before the default result',
      () async {
        final row = _row(7, 'old');
        final rows = [row];
        var current = ManageNoteTypesState(isLoading: false, noteTypes: rows);
        final callbackError = StateError('report-error callback failed');
        final events = <String>[];
        final plan = prepareManageNoteTypeRename(
          noteTypeId: 7,
          name: 'new',
          updateState: (update) {
            events.add('publish');
            current = update(current);
          },
        );

        await expectLater(
          plan.run<Object>(
            undoableOp: (operation) {
              events.add('undoable');
              return operation();
            },
            safeRename: (_, _) async {
              events.add('safe rename');
              return ManageNoteTypeRenameFailure(
                StateError('rename failed'),
                false,
              );
            },
            defaultResult: () {
              events.add('default result');
              return Object();
            },
            reportError: (_, {required isReportable}) {
              events.add('report error');
              throw callbackError;
            },
          ),
          throwsA(same(callbackError)),
        );

        expect(events, [
          'publish',
          'undoable',
          'safe rename',
          'publish',
          'report error',
        ]);
        expect(current.isLoading, isTrue);
        expect(current.noteTypes, same(rows));
        expect(current.error, isNull);
      },
    );

    test('state publisher exceptions stop the next host callback', () async {
      final callbackError = StateError('loading publisher failed');
      final events = <String>[];

      expect(
        () => prepareManageNoteTypeRename(
          noteTypeId: 7,
          name: 'new',
          updateState: (_) {
            events.add('publish');
            throw callbackError;
          },
        ),
        throwsA(same(callbackError)),
      );
      expect(events, ['publish']);
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
  useCount: id,
  isSelected: selected,
  shouldBeDisplayed: displayed,
);
