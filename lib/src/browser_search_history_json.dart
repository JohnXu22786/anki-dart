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
  static const Set<String> _fieldNames = {'q', 'did', 'f', 't', 'ntid', 's'};
  static const Set<int> _flagCodes = {0, 1, 2, 3, 4, 5, 6, 7};
  static const Set<int> _cardStateCodes = {0, 1, 2, 3, 4};
  static final BigInt _minimumLong = BigInt.parse('-9223372036854775808');
  static final BigInt _maximumLong = BigInt.parse('9223372036854775807');

  /// Encodes [entries] with the source's compact JSON field names and order.
  static String encode(Iterable<BrowserSearchHistoryEntry> entries) =>
      '[${entries.map(_encodeEntry).join(',')}]';

  /// Decodes a history string, returning an empty list if any entry is invalid.
  static List<BrowserSearchHistoryEntry> decode(String value) {
    try {
      final original = jsonDecode(value);
      final reservedStrings = <String>{};
      _collectJsonStrings(original, reservedStrings);
      final numericTokens = _quoteJsonNumbers(value, reservedStrings);
      final decoded = jsonDecode(
        numericTokens.json,
        reviver: (key, value) => numericTokens.values[value] ?? value,
      );
      if (decoded is! List) return const [];
      return List<BrowserSearchHistoryEntry>.unmodifiable(
        decoded.map(_decodeEntry),
      );
    } catch (_) {
      return const [];
    }
  }

  static String _encodeEntry(BrowserSearchHistoryEntry entry) {
    final encoded = StringBuffer('{"q":${jsonEncode(entry.query)}');
    if (entry.deckIds.isNotEmpty) {
      encoded.write(',"did":[${entry.deckIds.map(_requireLong).join(',')}]');
    }
    if (entry.flags.isNotEmpty) {
      encoded.write(',"f":[${entry.flags.map(_requireFlagCode).join(',')}]');
    }
    if (entry.tags.isNotEmpty) encoded.write(',"t":${jsonEncode(entry.tags)}');
    if (entry.noteTypeIds.isNotEmpty) {
      encoded.write(
        ',"ntid":[${entry.noteTypeIds.map(_requireLong).join(',')}]',
      );
    }
    if (entry.cardStateCodes.isNotEmpty) {
      encoded.write(
        ',"s":[${entry.cardStateCodes.map(_requireCardStateCode).join(',')}]',
      );
    }
    return '${encoded.toString()}}';
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

  static Object _readLong(Object? value) {
    final integer = _asBigInt(value);
    if (integer == null || !_isSignedLong(integer)) {
      throw const FormatException('Expected a signed 64-bit integer.');
    }
    final nativeInteger = int.tryParse(integer.toString());
    if (nativeInteger != null && BigInt.from(nativeInteger) == integer) {
      return nativeInteger;
    }
    return integer;
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
    final integer = _asBigInt(value);
    if (integer == null ||
        integer < BigInt.from(-0x80000000) ||
        integer > BigInt.from(0x7fffffff)) {
      throw const FormatException('Expected a signed 32-bit integer.');
    }
    return integer.toInt();
  }

  static String _readString(Object? value) {
    if (value is! String) throw const FormatException('Expected a string.');
    return value;
  }

  static String _requireLong(Object value) {
    final integer = _asBigInt(value);
    if (integer == null || !_isSignedLong(integer)) {
      throw ArgumentError.value(value, 'value', 'Must fit a signed 64-bit ID.');
    }
    return integer.toString();
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

  static bool _isSignedLong(BigInt value) =>
      value >= _minimumLong && value <= _maximumLong;

  static BigInt? _asBigInt(Object? value) => switch (value) {
    _JsonNumberLiteral(:final literal) => BigInt.tryParse(literal),
    BigInt integer => integer,
    int integer => BigInt.from(integer),
    _ => null,
  };

  static _QuotedJsonNumbers _quoteJsonNumbers(
    String json,
    Set<String> reservedStrings,
  ) {
    var prefix = '\u0000anki-dart-number-';
    while (json.contains(prefix) ||
        reservedStrings.any((value) => value.contains(prefix))) {
      prefix = '$prefix-';
    }
    final output = StringBuffer();
    final values = <String, _JsonNumberLiteral>{};
    var index = 0;
    var numberIndex = 0;
    while (index < json.length) {
      final character = json[index];
      if (character == '"') {
        final start = index++;
        while (index < json.length) {
          if (json[index] == '\\') {
            index += 2;
          } else if (json[index++] == '"') {
            break;
          }
        }
        output.write(json.substring(start, index));
        continue;
      }
      if (character == '-' || _isAsciiDigit(character)) {
        final match = _jsonNumber.matchAsPrefix(json, index);
        if (match == null) throw const FormatException('Invalid JSON number.');
        final literal = match.group(0)!;
        final marker = '$prefix${numberIndex++}';
        values[marker] = _JsonNumberLiteral(literal);
        output.write(jsonEncode(marker));
        index = match.end;
        continue;
      }
      output.write(character);
      index++;
    }
    return _QuotedJsonNumbers(output.toString(), values);
  }
}

void _collectJsonStrings(Object? value, Set<String> strings) {
  switch (value) {
    case String string:
      strings.add(string);
    case List<dynamic> list:
      for (final child in list) {
        _collectJsonStrings(child, strings);
      }
    case Map<dynamic, dynamic> map:
      for (final entry in map.entries) {
        _collectJsonStrings(entry.key, strings);
        _collectJsonStrings(entry.value, strings);
      }
  }
}

final RegExp _jsonNumber = RegExp(
  r'-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?',
);

bool _isAsciiDigit(String value) =>
    value.codeUnitAt(0) >= 0x30 && value.codeUnitAt(0) <= 0x39;

final class _JsonNumberLiteral {
  const _JsonNumberLiteral(this.literal);

  final String literal;
}

final class _QuotedJsonNumbers {
  const _QuotedJsonNumbers(this.json, this.values);

  final String json;
  final Map<String, _JsonNumberLiteral> values;
}
