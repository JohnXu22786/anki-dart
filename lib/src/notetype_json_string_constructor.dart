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

/// Adapts the pinned `NotetypeJson(json: String)` constructor.
///
/// The host parses the exact input string into its own JSON object and wraps
/// that object as its own `NotetypeJson`; parsing and wrapper failures pass
/// through unchanged.
final class NotetypeJsonStringConstructor<
  TJsonObject extends Object,
  TNotetypeJson extends Object
> {
  const NotetypeJsonStringConstructor({
    required TJsonObject Function(String jsonString) parseJsonObjectString,
    required TNotetypeJson Function(TJsonObject jsonObject) wrapJsonObject,
  }) : _parseJsonObjectString = parseJsonObjectString,
       _wrapJsonObject = wrapJsonObject;

  final TJsonObject Function(String jsonString) _parseJsonObjectString;
  final TNotetypeJson Function(TJsonObject jsonObject) _wrapJsonObject;

  /// Parses [jsonString] once and wraps that exact host JSON object once.
  TNotetypeJson construct(String jsonString) {
    final jsonObject = _parseJsonObjectString(jsonString);
    return _wrapJsonObject(jsonObject);
  }
}
