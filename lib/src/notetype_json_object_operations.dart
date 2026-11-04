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

/// Adapts host-owned JSON clone and string conversion for `NotetypeJson`.
///
/// The host retains the model and JSON object; all JSON behavior and failures
/// remain with the supplied callbacks.
final class NotetypeJsonObjectOperations<
  TNotetypeJson extends Object,
  TJsonObject extends Object,
  TClone extends Object
> {
  const NotetypeJsonObjectOperations({
    required TNotetypeJson notetypeJson,
    required TJsonObject Function(TNotetypeJson notetypeJson) getJsonObject,
    required TClone Function(TJsonObject jsonObject) deepCloneJsonObject,
    required TNotetypeJson Function(TClone jsonObject) wrapJsonObject,
    required String Function(TJsonObject jsonObject) jsonObjectToString,
  }) : _notetypeJson = notetypeJson,
       _getJsonObject = getJsonObject,
       _deepCloneJsonObject = deepCloneJsonObject,
       _wrapJsonObject = wrapJsonObject,
       _jsonObjectToString = jsonObjectToString;

  final TNotetypeJson _notetypeJson;
  final TJsonObject Function(TNotetypeJson notetypeJson) _getJsonObject;
  final TClone Function(TJsonObject jsonObject) _deepCloneJsonObject;
  final TNotetypeJson Function(TClone jsonObject) _wrapJsonObject;
  final String Function(TJsonObject jsonObject) _jsonObjectToString;

  /// Clones the retained host JSON object, then wraps that exact clone.
  TNotetypeJson deepClone() {
    final jsonObject = _getJsonObject(_notetypeJson);
    final clone = _deepCloneJsonObject(jsonObject);
    return _wrapJsonObject(clone);
  }

  /// Returns the retained host JSON object's string conversion unchanged.
  @override
  String toString() => _jsonObjectToString(_getJsonObject(_notetypeJson));
}
