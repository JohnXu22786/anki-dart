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
 * Source-derived from NotetypeJson.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// Adapts the `NotetypeJson.did` property around host-owned JSON operations.
///
/// The host retains the JSON object and its `isNull`, `optLong`, and `put`
/// behavior. A null `did` uses AnkiDroid's default deck ID of 1.
final class NotetypeDid {
  NotetypeDid({
    required Object jsonObject,
    required bool Function(Object jsonObject, String key) isNull,
    required int Function(Object jsonObject, String key, int fallback) optLong,
    required void Function(Object jsonObject, String key, Object? value) put,
  }) : _jsonObject = jsonObject,
       _isNull = isNull,
       _optLong = optLong,
       _put = put;

  static const _defaultDeckId = 1;

  final Object _jsonObject;
  final bool Function(Object jsonObject, String key) _isNull;
  final int Function(Object jsonObject, String key, int fallback) _optLong;
  final void Function(Object jsonObject, String key, Object? value) _put;

  /// Returns the host long value, or 1 when host `isNull("did")` is true.
  int get did => _isNull(_jsonObject, 'did')
      ? _defaultDeckId
      : _optLong(_jsonObject, 'did', _defaultDeckId);

  /// Writes [value] through the host JSON object's `put("did", value)`.
  set did(int value) {
    _put(_jsonObject, 'did', value);
  }
}
