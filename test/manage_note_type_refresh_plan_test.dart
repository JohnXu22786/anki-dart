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
 * Source-derived cases for ManageNoteTypesViewModel.refreshNoteTypes(); see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Manage Note Type refresh plan', () {
    test(
      'publishes loading before query scheduling and preserves other state on success',
      () async {
        final originalRow = _row(8, 'original');
        final first = _row(4, 'first', displayed: false);
        final second = _row(2, 'second', selected: true);
        final returnedRows = [first, second];
        final priorError = Object();
        var current = ManageNoteTypesState(
          isLoading: false,
          noteTypes: [originalRow],
          searchQuery: 'query',
          destination: const ManageNoteTypesCardEditor(8),
          error: priorError,
          message: 'prior message',
          isInMultiSelectMode: true,
        );
        final events = <String>[];
        final plan = prepareManageNoteTypeRefresh(
          updateState: (update) {
            events.add('publish');
            current = update(current);
          },
        );

        expect(events, ['publish']);
        expect(current.isLoading, isTrue);
        expect(current.noteTypes, [originalRow]);
        await plan.run(
          safeQuery: () async {
            events.add('schedule query');
            expect(current.isLoading, isTrue);
            return ManageNoteTypeRefreshSuccess(returnedRows);
          },
          reportError: (_) => fail('unexpected report error'),
        );

        expect(events, ['publish', 'schedule query', 'publish']);
        expect(current.isLoading, isFalse);
        expect(current.noteTypes, same(returnedRows));
        expect(current.noteTypes, [first, second]);
        expect(current.searchQuery, 'query');
        expect(current.destination, const ManageNoteTypesCardEditor(8));
        expect(current.error, same(priorError));
        expect(current.message, 'prior message');
        expect(current.isInMultiSelectMode, isTrue);
      },
    );

    test(
      'safe-query failure replaces error while retaining the latest state rows and fields',
      () async {
        final startingRow = _row(1, 'starting');
        final latestRow = _row(3, 'latest', displayed: false);
        final latestRows = [latestRow];
        final cause = StateError('collection unavailable');
        final wrappedError = Object();
        var current = ManageNoteTypesState(
          isLoading: false,
          noteTypes: [startingRow],
          searchQuery: 'keep query',
          destination: const ManageNoteTypesFieldsEditor(3, 'latest'),
          error: 'old error',
          message: 'keep message',
          isInMultiSelectMode: true,
        );
        Object? wrappedCause;
        final plan = prepareManageNoteTypeRefresh(
          updateState: (update) => current = update(current),
        );

        await plan.run(
          safeQuery: () async {
            current = current.copyWith(noteTypes: latestRows);
            return ManageNoteTypeRefreshFailure(cause);
          },
          reportError: (error) {
            wrappedCause = error;
            return wrappedError;
          },
        );

        expect(wrappedCause, same(cause));
        expect(current.isLoading, isFalse);
        expect(current.noteTypes, same(latestRows));
        expect(current.searchQuery, 'keep query');
        expect(
          current.destination,
          const ManageNoteTypesFieldsEditor(3, 'latest'),
        );
        expect(current.error, same(wrappedError));
        expect(current.message, 'keep message');
        expect(current.isInMultiSelectMode, isTrue);
      },
    );

    test(
      'host safe-query callback exceptions propagate without translation',
      () async {
        final cause = StateError('safe query callback failed');
        var current = ManageNoteTypesState(isLoading: false);
        var publications = 0;
        final plan = prepareManageNoteTypeRefresh(
          updateState: (update) {
            publications++;
            current = update(current);
          },
        );

        await expectLater(
          plan.run(
            safeQuery: () async => throw cause,
            reportError: (_) => 'must not wrap callback throws',
          ),
          throwsA(same(cause)),
        );

        expect(publications, 1);
        expect(current.isLoading, isTrue);
      },
    );

    test('initial and completion publisher exceptions propagate', () async {
      final initialError = StateError('initial publisher failed');
      expect(
        () => prepareManageNoteTypeRefresh(
          updateState: (_) => throw initialError,
        ),
        throwsA(same(initialError)),
      );

      final completionError = StateError('completion publisher failed');
      var publications = 0;
      var current = ManageNoteTypesState(isLoading: false);
      final plan = prepareManageNoteTypeRefresh(
        updateState: (update) {
          publications++;
          if (publications == 2) throw completionError;
          current = update(current);
        },
      );

      await expectLater(
        plan.run(
          safeQuery: () async =>
              ManageNoteTypeRefreshSuccess([_row(5, 'five')]),
          reportError: (_) => fail('unexpected report error'),
        ),
        throwsA(same(completionError)),
      );

      expect(publications, 2);
      expect(current.isLoading, isTrue);
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
  useCount: id + 10,
  isSelected: selected,
  shouldBeDisplayed: displayed,
);
