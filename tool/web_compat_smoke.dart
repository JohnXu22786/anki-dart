/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
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
 */

import '../lib/src/json_reader.dart';
import '../lib/src/locale_lowercase.dart';
import '../lib/src/browser_search_history.dart';
import '../lib/src/browser_search_history_json.dart';
import '../lib/src/browser_search_request.dart';

void main() {
  final reader = _Reader([
    (JsonReaderToken.beginObject, null),
    (JsonReaderToken.name, 'id'),
    (JsonReaderToken.number, '9007199254740993'),
    (JsonReaderToken.endObject, null),
    (JsonReaderToken.endDocument, null),
  ]);
  final result = readJsonObject(reader, _Containers());
  final id = result['id'] as JsonIntegerValue;
  if (id.value != BigInt.parse('9007199254740993') || !id.isLong) {
    throw StateError('Web target rounded a signed 64-bit JSON integer.');
  }
  if (localeLowercase('I', 'tr_TR') != 'ı') {
    throw StateError('Explicit Turkic locale behavior changed on web.');
  }

  const historyJson = '[{"q":"ids","did":[9007199254740993]}]';
  final history = BrowserSearchHistoryJsonCodec.decode(historyJson).single;
  if (history.deckIds.single != BigInt.parse('9007199254740993')) {
    throw StateError('Web target rounded a persisted browser history ID.');
  }
  final encoded = BrowserSearchHistoryJsonCodec.encode([
    BrowserSearchHistoryEntry(
      query: 'ids',
      deckIds: [BigInt.parse('9007199254740993')],
    ),
  ]);
  if (encoded != historyJson) {
    throw StateError('Web target changed a persisted browser history ID.');
  }

  final largeId = BigInt.parse('9007199254740993');
  final filters = BrowserSearchFilters.fromHistoryEntry(
    BrowserSearchHistoryEntry(query: 'ids', deckIds: [largeId]),
    deckNameMap: [BrowserDeckNameId(name: 'Large deck', id: largeId)],
    noteTypeMap: const [],
  );
  if (filters?.decks.single.id != largeId) {
    throw StateError('Web target failed to restore a large collection ID.');
  }
}

final class _Reader implements JsonReaderTokenReader {
  _Reader(this._tokens);

  final List<(JsonReaderToken, Object?)> _tokens;
  var _position = 0;
  (JsonReaderToken, Object?) get _current => _tokens[_position];

  @override
  JsonReaderToken peek() => _current.$1;

  Object? _consume(JsonReaderToken token) {
    if (peek() != token) throw StateError('Unexpected JSON token.');
    return _tokens[_position++].$2;
  }

  @override
  void beginObject() => _consume(JsonReaderToken.beginObject);

  @override
  void endObject() => _consume(JsonReaderToken.endObject);

  @override
  void beginArray() => _consume(JsonReaderToken.beginArray);

  @override
  void endArray() => _consume(JsonReaderToken.endArray);

  @override
  bool hasNext() =>
      peek() != JsonReaderToken.endObject &&
      peek() != JsonReaderToken.endArray &&
      peek() != JsonReaderToken.endDocument;

  @override
  String nextName() => _consume(JsonReaderToken.name)! as String;

  @override
  String nextString() {
    if (peek() != JsonReaderToken.string && peek() != JsonReaderToken.number) {
      throw StateError('Unexpected JSON token.');
    }
    return _tokens[_position++].$2! as String;
  }

  @override
  bool nextBoolean() => _consume(JsonReaderToken.boolean)! as bool;

  @override
  void nextNull() => _consume(JsonReaderToken.nullValue);
}

final class _Containers
    implements JsonReaderContainerAdapter<Map<String, Object?>, List<Object?>> {
  @override
  Map<String, Object?> createObject() => {};

  @override
  List<Object?> createArray() => [];

  @override
  Object jsonNullValue() => Object();

  @override
  void putObjectValue(Map<String, Object?> object, String name, Object? value) {
    object[name] = value;
  }

  @override
  void putArrayValue(List<Object?> array, Object? value) => array.add(value);

  @override
  Never malformedJson(String message) => throw FormatException(message);
}
