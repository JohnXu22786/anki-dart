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
 * Behavioral reference: ChangeNoteTypeViewModel.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'dart:collection';

/// Host-resolved name and ordinal for one note-type field.
typedef ChangeNoteTypeField = ({String name, int ordinal});

/// Projects AnkiDroid's default field mapping from ordered host-resolved fields.
///
/// Exact-name matches use the first input field with that name. Missing output
/// ordinals are then filled using the source's identity/first-unused rules.
/// Duplicate output ordinals keep the last name match, and the mapping retains
/// any matched keys outside `0 .. outputFields.length - 1`.
Map<int, int?> projectChangeNoteTypeDefaultFieldMap({
  required List<ChangeNoteTypeField> inputFields,
  required List<ChangeNoteTypeField> outputFields,
}) {
  final currentOrdMapping = HashMap<int, int?>();

  for (final outputField in outputFields) {
    ChangeNoteTypeField? firstMatch;
    for (final inputField in inputFields) {
      if (inputField.name == outputField.name) {
        firstMatch = inputField;
        break;
      }
    }
    if (firstMatch != null) {
      currentOrdMapping[outputField.ordinal] = firstMatch.ordinal;
    }
  }

  final unmappedOrds = List<int>.generate(
    outputFields.length,
    (ord) => ord,
  ).where((ord) => !currentOrdMapping.containsKey(ord)).toList(growable: false);

  for (final unmappedOrd in unmappedOrds) {
    if (currentOrdMapping.length >= inputFields.length) {
      currentOrdMapping[unmappedOrd] = null;
    } else if (!currentOrdMapping.containsValue(unmappedOrd)) {
      currentOrdMapping[unmappedOrd] = unmappedOrd;
    } else {
      int? firstUnusedInputOrd;
      for (var inputOrd = 0; inputOrd < inputFields.length; inputOrd++) {
        if (!currentOrdMapping.containsValue(inputOrd)) {
          firstUnusedInputOrd = inputOrd;
          break;
        }
      }
      currentOrdMapping[unmappedOrd] = firstUnusedInputOrd;
    }
  }

  return currentOrdMapping;
}
