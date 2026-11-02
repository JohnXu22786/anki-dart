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
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral references: SearchHistory.kt, Flag.kt, CardState.kt, and
 * PythonTypes.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'dart:convert';

import 'browser_search_history.dart';

/// Encodes and decodes AnkiDroid's Card Browser search-history JSON values.
///
/// The host remains responsible for loading and saving the returned string.
/// Invalid JSON or an incompatible entry decodes as an empty whole history,
/// matching the source's `runCatching` fallback.
abstract final class BrowserSearchHistoryJsonCodec {
  static const Set<String> _fieldNames = {
    'q',
    'did',
    'f',
    't',
    'ntid',
    's',
  };
  static const Set<int> _flagCodes = {0, 1, 2, 3, 4, 5, 6, 7};
  static const Set<int> _cardStateCodes = {0, 1, 2, 3, 4};
  static final BigInt _minimumLong = BigInt.parse('-9223372036854775808');
  static final BigInt _maximumLong = BigInt.parse('9223372036854775807');

  /// Encodes [entries] with the source's compact JSON field names and order.
  static String encode(Iterable<BrowserSearchHistoryEntry> entries) =>
      jsonEncode(entries.map(_encodeEntry).toList(growable: false));

  /// Decodes a history string, returning an empty list if any entry is invalid.
  static List<BrowserSearchHistoryEntry> decode(String value) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is! List) return const [];
      return List<BrowserSearchHistoryEntry>.unmodifiable(
        decoded.map(_decodeEntry),
      );
    } catch (_) {
      return const [];
    }
  }

  static Map<String, Object?> _encodeEntry(BrowserSearchHistoryEntry entry) {
    final encoded = <String, Object?>{'q': entry.query};
    if (entry.deckIds.isNotEmpty) {
      encoded['did'] = entry.deckIds.map(_requireLong).toList(growable: false);
    }
    if (entry.flags.isNotEmpty) {
      encoded['f'] = entry.flags.map(_requireFlagCode).toList(growable: false);
    }
    if (entry.tags.isNotEmpty) encoded['t'] = entry.tags;
    if (entry.noteTypeIds.isNotEmpty) {
      encoded['ntid'] =
          entry.noteTypeIds.map(_requireLong).toList(growable: false);
    }
    if (entry.cardStateCodes.isNotEmpty) {
      encoded['s'] = entry.cardStateCodes
          .map(_requireCardStateCode)
          .toList(growable: false);
    }
    return encoded;
  }

  static BrowserSearchHistoryEntry _decodeEntry(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Expected a search-history object.');
    }
    if (value.keys.any((key) => !_fieldNames.contains(key))) {
      throw const FormatException('Unknown search-history field.');
    }
    final query = value['q'];
    if (query is! String) {
      throw const FormatException('Expected a string query.');
    }
    return BrowserSearchHistoryEntry(
      query: query,
      deckIds: _readOptionalList(value, 'did', _readLong),
      flags: _readOptionalList(value, 'f', _readFlagCode),
      tags: _readOptionalList(value, 't', _readString),
      noteTypeIds: _readOptionalList(value, 'ntid', _readLong),
      cardStateCodes: _readOptionalList(value, 's', _readCardStateCode),
    );
  }

  static List<T> _readOptionalList<T>(
    Map<String, dynamic> entry,
    String key,
    T Function(Object?) readValue,
  ) {
    if (!entry.containsKey(key)) return const [];
    final value = entry[key];
    if (value is! List) {
      throw FormatException('Expected a list for "$key".');
    }
    return value.map(readValue).toList(growable: false);
  }

  static int _readLong(Object? value) {
    if (value is! int || !_isSignedLong(value)) {
      throw const FormatException('Expected a signed 64-bit integer.');
    }
    return value;
  }

  static int _readFlagCode(Object? value) {
    final code = _readInt32(value);
    if (!_flagCodes.contains(code)) {
      throw FormatException('Unknown flag code: $code.');
    }
    return code;
  }

  static int _readCardStateCode(Object? value) {
    final code = _readInt32(value);
    if (!_cardStateCodes.contains(code)) {
      throw FormatException('Unknown card-state code: $code.');
    }
    return code;
  }

  static int _readInt32(Object? value) {
    if (value is! int || value < -0x80000000 || value > 0x7fffffff) {
      throw const FormatException('Expected a signed 32-bit integer.');
    }
    return value;
  }

  static String _readString(Object? value) {
    if (value is! String) throw const FormatException('Expected a string.');
    return value;
  }

  static int _requireLong(int value) {
    if (!_isSignedLong(value)) {
      throw ArgumentError.value(value, 'value', 'Must fit a signed 64-bit ID.');
    }
    return value;
  }

  static int _requireFlagCode(int value) {
    if (!_flagCodes.contains(value)) {
      throw ArgumentError.value(value, 'value', 'Unknown flag code.');
    }
    return value;
  }

  static int _requireCardStateCode(int value) {
    if (!_cardStateCodes.contains(value)) {
      throw ArgumentError.value(value, 'value', 'Unknown card-state code.');
    }
    return value;
  }

  static bool _isSignedLong(int value) {
    final integer = BigInt.from(value);
    return integer >= _minimumLong && integer <= _maximumLong;
  }
}
