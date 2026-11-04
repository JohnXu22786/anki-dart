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

/// Adapts `NotetypeJson.update(updateFrom)` around host-owned JSON operations.
///
/// The host provides the source's key iteration, source value lookup, and
/// destination `JSONObject.put`. The key iterable is requested once and
/// traversed in its own order; each source value is read once immediately
/// before its matching destination put. Host values and failures pass through
/// unchanged.
final class NotetypeJsonUpdate<TJson extends Object, TValue> {
  const NotetypeJsonUpdate({
    required TJson sourceJsonObject,
    required TJson destinationJsonObject,
    required Iterable<String> Function(TJson sourceJsonObject) keys,
    required TValue Function(TJson sourceJsonObject, String key) get,
    required void Function(
      TJson destinationJsonObject,
      String key,
      TValue value,
    )
    put,
  }) : _sourceJsonObject = sourceJsonObject,
       _destinationJsonObject = destinationJsonObject,
       _keys = keys,
       _get = get,
       _put = put;

  final TJson _sourceJsonObject;
  final TJson _destinationJsonObject;
  final Iterable<String> Function(TJson sourceJsonObject) _keys;
  final TValue Function(TJson sourceJsonObject, String key) _get;
  final void Function(TJson destinationJsonObject, String key, TValue value)
  _put;

  /// Overwrites destination values from source values in host key order.
  void update() {
    for (final key in _keys(_sourceJsonObject)) {
      final value = _get(_sourceJsonObject, key);
      _put(_destinationJsonObject, key, value);
    }
  }
}
