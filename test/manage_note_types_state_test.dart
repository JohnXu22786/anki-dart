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
 * Source-derived from ManageNoteTypesState.kt and ManageNoteTypesViewModel.kt
 * in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('ManageNoteTypesState', () {
    test('filter keeps rows and selections while updating display state', () {
      final alpha = _row(1, 'Alpha', selected: true);
      final beta = _row(2, 'Beta');
      final state = ManageNoteTypesState(
        isLoading: true,
        noteTypes: [alpha, beta],
        searchQuery: 'old',
        isInMultiSelectMode: true,
      );

      final filtered = state.filter('aLP');

      expect(filtered.noteTypes, hasLength(2));
      expect(filtered.noteTypes[0].shouldBeDisplayed, isTrue);
      expect(filtered.noteTypes[0].isSelected, isTrue);
      expect(filtered.noteTypes[1].shouldBeDisplayed, isFalse);
      expect(filtered.noteTypes[1].isSelected, isFalse);
      expect(filtered.searchQuery, 'aLP');
      expect(filtered.isLoading, isFalse);
      expect(filtered.isInMultiSelectMode, isTrue);
    });

    test('filter uses Kotlin case-insensitive character matching', () {
      final state = ManageNoteTypesState(
        noteTypes: [_row(1, 'I'), _row(2, 'İ')],
      );

      expect(state.filter('ı').noteTypes.first.shouldBeDisplayed, isTrue);
      expect(state.filter('i').noteTypes.map((row) => row.shouldBeDisplayed), [
        true,
        true,
      ]);
    });

    test('filter uses simple uppercase mappings when full casing expands', () {
      final state = ManageNoteTypesState(noteTypes: [_row(1, '\u1F80')]);

      expect(state.filter('\u1F88').noteTypes.single.shouldBeDisplayed, isTrue);
    });

    test(
      'filter ignores full uppercase expansions without simple mappings',
      () {
        final state = ManageNoteTypesState(noteTypes: [_row(1, '\u0390')]);

        expect(
          state.filter('\u0399').noteTypes.single.shouldBeDisplayed,
          isFalse,
        );
      },
    );

    test(
      'click routes outside selection and toggles rows inside selection',
      () {
        final alpha = _row(1, 'Alpha');
        final beta = _row(2, 'Beta');
        final state = ManageNoteTypesState(noteTypes: [alpha, beta]);

        final routed = state.onItemClick(beta);
        expect(routed.noteTypes, same(state.noteTypes));
        expect(routed.destination, isA<ManageNoteTypesFieldsEditor>());
        final fieldsEditor = routed.destination! as ManageNoteTypesFieldsEditor;
        expect(fieldsEditor.noteTypeId, beta.id);
        expect(fieldsEditor.name, beta.name);

        final started = state.onItemLongClick(alpha);
        expect(started.noteTypes[0].isSelected, isTrue);
        expect(started.isInMultiSelectMode, isTrue);

        final added = started.onItemClick(beta);
        expect(added.noteTypes.map((row) => row.isSelected), [true, true]);
        expect(added.isInMultiSelectMode, isTrue);

        final ended = added.onItemClick(alpha);
        expect(ended.noteTypes.map((row) => row.isSelected), [false, true]);
        expect(ended.isInMultiSelectMode, isTrue);
        expect(ended.onItemLongClick(beta).isInMultiSelectMode, isFalse);
      },
    );

    test('long click toggles while selecting and starts mode otherwise', () {
      final alpha = _row(1, 'Alpha');
      final beta = _row(2, 'Beta');
      final started = ManageNoteTypesState(
        noteTypes: [alpha, beta],
      ).onItemLongClick(alpha);

      expect(started.noteTypes.map((row) => row.isSelected), [true, false]);
      expect(started.isInMultiSelectMode, isTrue);

      final added = started.onItemLongClick(beta);
      expect(added.noteTypes.map((row) => row.isSelected), [true, true]);
      expect(added.isInMultiSelectMode, isTrue);

      final ended = added.onItemLongClick(alpha);
      expect(ended.noteTypes.map((row) => row.isSelected), [false, true]);
      expect(ended.isInMultiSelectMode, isTrue);
    });

    test(
      'checked state and clear selection derive mode from selected rows',
      () {
        final alpha = _row(1, 'Alpha');
        final beta = _row(2, 'Beta', selected: true);
        final state = ManageNoteTypesState(
          noteTypes: [beta, alpha],
          isInMultiSelectMode: true,
        );

        final checked = state.onItemChecked(alpha, true);
        expect(checked.isInMultiSelectMode, isTrue);
        expect(checked.selectedNoteTypes.map((row) => row.name), [
          'Beta',
          'Alpha',
        ]);

        final unchecked = checked.onItemChecked(beta, false);
        expect(unchecked.isInMultiSelectMode, isTrue);
        expect(unchecked.selectedNoteTypes.map((row) => row.name), ['Alpha']);

        final cleared = unchecked.clearSelection();
        expect(cleared.selectedNoteTypes, isEmpty);
        expect(cleared.isInMultiSelectMode, isFalse);
        expect(cleared.noteTypes.map((row) => row.name), ['Beta', 'Alpha']);
      },
    );

    test('selection update changes every row with the requested ID', () {
      final first = _row(7, 'First');
      final second = _row(7, 'Second');

      final selected = ManageNoteTypesState(
        noteTypes: [first, second],
      ).onItemLongClick(first);

      expect(selected.noteTypes.map((row) => row.isSelected), [true, true]);
      expect(selected.selectedNoteTypes.map((row) => row.name), [
        'First',
        'Second',
      ]);
    });

    test('card editor destination can be cleared', () {
      final row = _row(4, 'Cards');
      final requested = ManageNoteTypesState(
        noteTypes: [row],
      ).onCardEditorRequested(row);

      expect(requested.destination, isA<ManageNoteTypesCardEditor>());
      expect(
        (requested.destination! as ManageNoteTypesCardEditor).noteTypeId,
        row.id,
      );
      expect(requested.clearDestination().destination, isNull);
    });

    test('clearMessage clears only the latest state message', () {
      final error = StateError('keep error');
      final destination = ManageNoteTypesFieldsEditor(4, 'latest');
      final rows = [_row(4, 'latest', selected: true)];
      final state = ManageNoteTypesState(
        isLoading: false,
        noteTypes: rows,
        searchQuery: 'late',
        destination: destination,
        error: error,
        message: 'dismissed',
        isInMultiSelectMode: true,
      );

      final cleared = state.clearMessage();

      expect(cleared.message, isNull);
      expect(cleared.error, same(error));
      expect(cleared.isLoading, state.isLoading);
      expect(cleared.noteTypes, same(rows));
      expect(cleared.searchQuery, state.searchQuery);
      expect(cleared.destination, same(destination));
      expect(cleared.isInMultiSelectMode, state.isInMultiSelectMode);
    });

    test('clearError clears only the latest state error', () {
      final error = StateError('dismissed error');
      final message = Object();
      final destination = ManageNoteTypesCardEditor(9);
      final rows = [_row(9, 'current', selected: true)];
      final state = ManageNoteTypesState(
        isLoading: false,
        noteTypes: rows,
        searchQuery: 'curr',
        destination: destination,
        error: error,
        message: message,
        isInMultiSelectMode: true,
      );

      final cleared = state.clearError();

      expect(cleared.error, isNull);
      expect(cleared.message, same(message));
      expect(cleared.isLoading, state.isLoading);
      expect(cleared.noteTypes, same(rows));
      expect(cleared.searchQuery, state.searchQuery);
      expect(cleared.destination, same(destination));
      expect(cleared.isInMultiSelectMode, state.isInMultiSelectMode);
    });
  });
}

NoteTypeItemState _row(int id, String name, {bool selected = false}) =>
    NoteTypeItemState(id: id, name: name, useCount: 0, isSelected: selected);
