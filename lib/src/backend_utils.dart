/*
 * Copyright (c) 2021 David Allison <davidallisongithub@gmail.com>
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
 * SPDX-FileCopyrightText: 2021 David Allison <davidallisongithub@gmail.com>
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from BackendUtils.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'json_container.dart';

/// Host operations used by AnkiDroid's `BackendUtils` JSON/ByteString helpers.
///
/// JSON representations and UTF-8 behavior stay on host callbacks. This adapter
/// preserves only the source operation order and passes callback values through
/// unchanged.
final class BackendUtilsHostAdapter<TObject, TArray, TByteString> {
  const BackendUtilsHostAdapter({
    required String Function(TByteString bytes) stringFromUtf8,
    required TObject Function(String json) createJsonObject,
    required TArray Function(String json) createJsonArray,
    required String Function(TObject object) jsonObjectToString,
    required TByteString Function(String json) copyFromUtf8,
    required TObject Function(JSONObjectHolder holder) holderJsonObject,
  }) : _stringFromUtf8 = stringFromUtf8,
       _createJsonObject = createJsonObject,
       _createJsonArray = createJsonArray,
       _jsonObjectToString = jsonObjectToString,
       _copyFromUtf8 = copyFromUtf8,
       _holderJsonObject = holderJsonObject;

  final String Function(TByteString bytes) _stringFromUtf8;
  final TObject Function(String json) _createJsonObject;
  final TArray Function(String json) _createJsonArray;
  final String Function(TObject object) _jsonObjectToString;
  final TByteString Function(String json) _copyFromUtf8;
  final TObject Function(JSONObjectHolder holder) _holderJsonObject;

  /// Converts host bytes once, then delegates parsing and construction to host.
  TObject fromJsonBytes(TByteString bytes) =>
      _createJsonObject(_stringFromUtf8(bytes));

  /// Converts host bytes once, then delegates array parsing to host.
  TArray jsonToArray(TByteString bytes) =>
      _createJsonArray(_stringFromUtf8(bytes));

  /// Serializes once through the host object, then copies through host bytes.
  TByteString toByteString(TObject object) =>
      _copyFromUtf8(_jsonObjectToString(object));

  /// Source-equivalent `toJsonBytes(JSONObject)` overload.
  TByteString toJsonBytes(TObject object) => toByteString(object);

  /// Source-equivalent `toJsonBytes(JSONObjectHolder)` overload.
  TByteString toJsonBytesFromHolder(JSONObjectHolder holder) =>
      toJsonBytes(_holderJsonObject(holder));
}
