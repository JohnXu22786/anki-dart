/*
 * Copyright (c) 2020 Arthur Milchior <arthur@milchior.fr>
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
 * SPDX-FileCopyrightText: 2020 Arthur Milchior <arthur@milchior.fr>
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from NotetypeJson.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'libanki_consts.dart';

/// Adapts the pinned `NotetypeJson.isStd` and `isCloze` getters.
///
/// The host owns `NotetypeJson`, `JSONObject`, and JSON access. Each property
/// reads the host integer `type` value once, then maps its code using
/// [LibAnkiNoteTypeKind.fromCode].
final class NotetypeJsonTypePredicates<TJson extends Object> {
  const NotetypeJsonTypePredicates({
    required TJson jsonObject,
    required int Function(TJson jsonObject, String key) getInt,
  }) : _jsonObject = jsonObject,
       _getInt = getInt;

  final TJson _jsonObject;
  final int Function(TJson jsonObject, String key) _getInt;

  /// Whether the host `type` integer identifies the standard note type.
  bool get isStd =>
      LibAnkiNoteTypeKind.fromCode(_getInt(_jsonObject, 'type')) ==
      LibAnkiNoteTypeKind.std;

  /// Whether the host `type` integer identifies the cloze note type.
  bool get isCloze =>
      LibAnkiNoteTypeKind.fromCode(_getInt(_jsonObject, 'type')) ==
      LibAnkiNoteTypeKind.cloze;
}
