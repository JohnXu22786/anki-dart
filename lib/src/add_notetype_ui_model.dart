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
 * Behavioral reference: NotetypeUiModel.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'kotlin_string_hash_code.dart';

/// Data shown for one note type in the add-note-type list.
///
/// Note-type IDs are supplied by the host as Dart integers; collection lookup,
/// generated protobufs and Android list/UI behavior remain host-side.
final class AddNotetypeUiModel {
  const AddNotetypeUiModel({
    required this.id,
    required this.name,
    this.isStandard = false,
  });

  /// The note type's stable ID (`NoteTypeId`, a Kotlin `Long` upstream).
  final int id;

  /// The note type's display name.
  final String name;

  /// Whether Anki provides this note type by default.
  final bool isStandard;

  @override
  bool operator ==(Object other) =>
      other is AddNotetypeUiModel &&
      other.id == id &&
      other.name == name &&
      other.isStandard == isStandard;

  @override
  int get hashCode => _kotlinDataClassHashCode([
    _kotlinLongHashCode(id),
    kotlinStringHashCode(name),
    isStandard ? 1231 : 1237,
  ]);
}

/// Converts host-supplied `NotetypeNameId` fields to the UI model.
///
/// This mirrors `NotetypeNameId.toUiModel()` without requiring Anki's generated
/// protobuf type. Collection note types are not standard note types.
AddNotetypeUiModel addNotetypeUiModelFromNameId({
  required int id,
  required String name,
}) => AddNotetypeUiModel(id: id, name: name, isStandard: false);

int _kotlinLongHashCode(int value) => _kotlinInt32(value ^ (value >> 32));

int _kotlinDataClassHashCode(List<int> fields) {
  var hash = fields.first;
  for (final field in fields.skip(1)) {
    hash = _kotlinInt32(31 * hash + field);
  }
  return hash;
}

int _kotlinInt32(int value) {
  final unsigned = value & 0xFFFFFFFF;
  return unsigned >= 0x80000000 ? unsigned - 0x100000000 : unsigned;
}
