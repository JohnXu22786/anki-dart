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
 * SPDX-FileCopyrightText: 2025 lukstbit <52494258+lukstbit@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Adapted from ManageNoteTypesState.kt and the selection/filter transitions
 * in ManageNoteTypesViewModel.kt; simple UTF-16 case mappings are from Unicode
 * 15.0.0 UnicodeData.txt and separately licensed; see ANKIDROID_UPSTREAM.md.
 */

import 'unicode_15_simple_case_mappings.dart';

/// Host-supplied row data for Manage Note Types.
final class NoteTypeItemState {
  const NoteTypeItemState({
    required this.id,
    required this.name,
    required this.useCount,
    this.isSelected = false,
    this.shouldBeDisplayed = true,
  });

  final int id;
  final String name;
  final int useCount;
  final bool isSelected;
  final bool shouldBeDisplayed;

  NoteTypeItemState copyWith({
    String? name,
    bool? isSelected,
    bool? shouldBeDisplayed,
  }) => NoteTypeItemState(
    id: id,
    name: name ?? this.name,
    useCount: useCount,
    isSelected: isSelected ?? this.isSelected,
    shouldBeDisplayed: shouldBeDisplayed ?? this.shouldBeDisplayed,
  );
}

/// Host-facing navigation request from Manage Note Types.
sealed class ManageNoteTypesDestination {
  const ManageNoteTypesDestination();
}

/// Request to open Card Templates for the supplied note type.
final class ManageNoteTypesCardEditor extends ManageNoteTypesDestination {
  const ManageNoteTypesCardEditor(this.noteTypeId);

  final int noteTypeId;
}

/// Request to open Fields for the supplied note type.
final class ManageNoteTypesFieldsEditor extends ManageNoteTypesDestination {
  const ManageNoteTypesFieldsEditor(this.noteTypeId, this.name);

  final int noteTypeId;
  final String name;
}

/// Portable Manage Note Types state and its synchronous list transitions.
final class ManageNoteTypesState {
  const ManageNoteTypesState({
    this.isLoading = true,
    this.noteTypes = const [],
    this.searchQuery = '',
    this.destination,
    this.error,
    this.message,
    this.isInMultiSelectMode = false,
  });

  final bool isLoading;
  final List<NoteTypeItemState> noteTypes;
  final String searchQuery;
  final ManageNoteTypesDestination? destination;
  final Object? error;
  final Object? message;
  final bool isInMultiSelectMode;

  /// Selected rows in their original list order.
  List<NoteTypeItemState> get selectedNoteTypes =>
      noteTypes.where((noteType) => noteType.isSelected).toList();

  /// Updates display flags for every row without discarding selection.
  ManageNoteTypesState filter(String query) {
    final matchedNoteTypes = noteTypes
        .map(
          (noteType) => noteType.copyWith(
            shouldBeDisplayed: _containsIgnoringCase(noteType.name, query),
          ),
        )
        .toList();
    return _copyWith(
      isLoading: false,
      noteTypes: matchedNoteTypes,
      searchQuery: query,
    );
  }

  /// Toggles a row in multi-select mode; otherwise requests the fields editor.
  ManageNoteTypesState onItemClick(NoteTypeItemState entry) {
    if (!isInMultiSelectMode) {
      return _copyWith(
        destination: ManageNoteTypesFieldsEditor(entry.id, entry.name),
      );
    }

    final updatedNoteTypes = _withUpdatedItem(entry.id, (noteType) {
      return noteType.copyWith(isSelected: !noteType.isSelected);
    });
    return _copyWith(
      noteTypes: updatedNoteTypes,
      isInMultiSelectMode: _hasSelectedItem(updatedNoteTypes),
    );
  }

  /// Starts multi-select mode or toggles a row when already selecting.
  ManageNoteTypesState onItemLongClick(NoteTypeItemState entry) {
    if (isInMultiSelectMode) {
      final updatedNoteTypes = _withUpdatedItem(entry.id, (noteType) {
        return noteType.copyWith(isSelected: !noteType.isSelected);
      });
      return _copyWith(
        noteTypes: updatedNoteTypes,
        isInMultiSelectMode: _hasSelectedItem(updatedNoteTypes),
      );
    }

    final updatedNoteTypes = _withUpdatedItem(
      entry.id,
      (noteType) => noteType.copyWith(isSelected: true),
    );
    return _copyWith(noteTypes: updatedNoteTypes, isInMultiSelectMode: true);
  }

  /// Assigns [isChecked] to matching rows and derives the selection mode.
  ManageNoteTypesState onItemChecked(NoteTypeItemState entry, bool isChecked) {
    final updatedNoteTypes = _withUpdatedItem(
      entry.id,
      (noteType) => noteType.copyWith(isSelected: isChecked),
    );
    return _copyWith(
      noteTypes: updatedNoteTypes,
      isInMultiSelectMode: _hasSelectedItem(updatedNoteTypes),
    );
  }

  /// Clears row selection and derives the now-inactive selection mode.
  ManageNoteTypesState clearSelection() {
    final updatedNoteTypes = noteTypes
        .map((noteType) => noteType.copyWith(isSelected: false))
        .toList();
    return _copyWith(
      noteTypes: updatedNoteTypes,
      isInMultiSelectMode: _hasSelectedItem(updatedNoteTypes),
    );
  }

  /// Requests the Card Templates editor for [entry].
  ManageNoteTypesState onCardEditorRequested(NoteTypeItemState entry) =>
      _copyWith(destination: ManageNoteTypesCardEditor(entry.id));

  /// Consumes any pending destination.
  ManageNoteTypesState clearDestination() => _copyWith(destination: null);

  List<NoteTypeItemState> _withUpdatedItem(
    int id,
    NoteTypeItemState Function(NoteTypeItemState) update,
  ) => noteTypes
      .map((noteType) => noteType.id == id ? update(noteType) : noteType)
      .toList();

  static bool _hasSelectedItem(List<NoteTypeItemState> noteTypes) =>
      noteTypes.any((noteType) => noteType.isSelected);

  /// Copies the state while retaining omitted host-owned fields.
  ManageNoteTypesState copyWith({
    bool? isLoading,
    List<NoteTypeItemState>? noteTypes,
    String? searchQuery,
    Object? destination = _unchangedValue,
    Object? error = _unchangedValue,
    Object? message = _unchangedValue,
    bool? isInMultiSelectMode,
  }) => _copyWith(
    isLoading: isLoading,
    noteTypes: noteTypes,
    searchQuery: searchQuery,
    destination: destination,
    error: error,
    message: message,
    isInMultiSelectMode: isInMultiSelectMode,
  );

  ManageNoteTypesState _copyWith({
    bool? isLoading,
    List<NoteTypeItemState>? noteTypes,
    String? searchQuery,
    Object? destination = _unchangedValue,
    Object? error = _unchangedValue,
    Object? message = _unchangedValue,
    bool? isInMultiSelectMode,
  }) => ManageNoteTypesState(
    isLoading: isLoading ?? this.isLoading,
    noteTypes: noteTypes ?? this.noteTypes,
    searchQuery: searchQuery ?? this.searchQuery,
    destination: identical(destination, _unchangedValue)
        ? this.destination
        : destination as ManageNoteTypesDestination?,
    error: identical(error, _unchangedValue) ? this.error : error,
    message: identical(message, _unchangedValue) ? this.message : message,
    isInMultiSelectMode: isInMultiSelectMode ?? this.isInMultiSelectMode,
  );
}

const Object _unchangedValue = Object();

bool _containsIgnoringCase(String value, String query) {
  if (query.length > value.length) return false;
  for (var start = 0; start <= value.length - query.length; start++) {
    var matches = true;
    for (var offset = 0; offset < query.length; offset++) {
      if (!_sameCharIgnoringCase(
        value.codeUnitAt(start + offset),
        query.codeUnitAt(offset),
      )) {
        matches = false;
        break;
      }
    }
    if (matches) return true;
  }
  return false;
}

bool _sameCharIgnoringCase(int first, int second) {
  if (first == second) return true;
  final firstUpper = _simpleUpperCase(first);
  final secondUpper = _simpleUpperCase(second);
  return firstUpper == secondUpper ||
      _simpleLowerCase(firstUpper) == _simpleLowerCase(secondUpper);
}

int _simpleUpperCase(int codeUnit) =>
    unicode15SimpleUppercaseMappings[codeUnit] ?? codeUnit;

int _simpleLowerCase(int codeUnit) =>
    unicode15SimpleLowercaseMappings[codeUnit] ?? codeUnit;
