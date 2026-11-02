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
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from JsonReader.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// Tokens exposed by a host adapter for Android's streaming `JsonReader`.
enum JsonReaderToken {
  beginArray,
  beginObject,
  boolean,
  endArray,
  endDocument,
  endObject,
  name,
  nullValue,
  number,
  string,
}

extension JsonReaderTokenSourceName on JsonReaderToken {
  /// The spelling used by Android's `JsonToken.toString()` in source errors.
  String get sourceName => switch (this) {
    JsonReaderToken.beginArray => 'BEGIN_ARRAY',
    JsonReaderToken.beginObject => 'BEGIN_OBJECT',
    JsonReaderToken.boolean => 'BOOLEAN',
    JsonReaderToken.endArray => 'END_ARRAY',
    JsonReaderToken.endDocument => 'END_DOCUMENT',
    JsonReaderToken.endObject => 'END_OBJECT',
    JsonReaderToken.name => 'NAME',
    JsonReaderToken.nullValue => 'NULL',
    JsonReaderToken.number => 'NUMBER',
    JsonReaderToken.string => 'STRING',
  };
}

/// Streaming operations the host maps to Android's `JsonReader` methods.
///
/// This interface deliberately does not close the reader. The host owns its
/// lifecycle, UTF-8 decoding, tokenization, and parser exception types.
abstract interface class JsonReaderTokenReader {
  JsonReaderToken peek();

  void beginObject();

  void endObject();

  void beginArray();

  void endArray();

  bool hasNext();

  String nextName();

  String nextString();

  bool nextBoolean();

  void nextNull();
}

/// Host constructors and `put` operations for its JSON object/array types.
///
/// An Android host can create `JSONObject` and `JSONArray`, return
/// `JSONObject.NULL`, and let their `put` failures pass through unchanged.
/// [malformedJson] should throw the host's malformed-JSON exception.
abstract interface class JsonReaderContainerAdapter<
  TObject extends Object,
  TArray extends Object
> {
  TObject createObject();

  TArray createArray();

  Object jsonNullValue();

  void putObjectValue(TObject object, String name, Object? value);

  void putArrayValue(TArray array, Object? value);

  Never malformedJson(String message);
}

/// A JSON integer and the source Kotlin/JVM boxed width that held it.
///
/// The host maps [isLong] to `Long` and false to `Int`. Dart has one integer
/// type, so this wrapper preserves the distinction needed by `org.json` hosts.
final class JsonIntegerValue {
  const JsonIntegerValue(this.value, {required this.isLong});

  final int value;
  final bool isLong;

  @override
  bool operator ==(Object other) =>
      other is JsonIntegerValue &&
      other.value == value &&
      other.isLong == isLong;

  @override
  int get hashCode => Object.hash(value, isLong);

  @override
  String toString() => value.toString();
}

/// Reads one object from [reader], leaving the reader open for its caller.
///
/// This follows `JsonReader.readObject()`: the first token is checked before
/// consumption; containers are constructed and populated in source order;
/// JSON null uses the host sentinel; integer tokens preserve signed 32/64-bit
/// width; and host parsing, container, and exception failures propagate.
TObject readJsonObject<TObject extends Object, TArray extends Object>(
  JsonReaderTokenReader reader,
  JsonReaderContainerAdapter<TObject, TArray> containers,
) {
  if (reader.peek() != JsonReaderToken.beginObject) {
    containers.malformedJson('Expected a JSON object');
  }
  reader.beginObject();
  final result = containers.createObject();
  while (reader.hasNext()) {
    final name = reader.nextName();
    final value = _readJsonValue(reader, containers);
    containers.putObjectValue(result, name, value);
  }
  reader.endObject();
  return result;
}

/// Reads one object and requires the next token to be end-of-document.
///
/// Like `File.readJson()`, the host must close its reader even when this method
/// throws. File IO, UTF-8 reader construction, and Android exception identity
/// remain host-side.
TObject readSingleJsonObject<TObject extends Object, TArray extends Object>(
  JsonReaderTokenReader reader,
  JsonReaderContainerAdapter<TObject, TArray> containers,
) {
  final result = readJsonObject(reader, containers);
  if (reader.peek() != JsonReaderToken.endDocument) {
    containers.malformedJson('Unexpected data after JSON object');
  }
  return result;
}

Object? _readJsonValue<TObject extends Object, TArray extends Object>(
  JsonReaderTokenReader reader,
  JsonReaderContainerAdapter<TObject, TArray> containers,
) {
  switch (reader.peek()) {
    case JsonReaderToken.beginObject:
      return readJsonObject(reader, containers);
    case JsonReaderToken.beginArray:
      reader.beginArray();
      final result = containers.createArray();
      while (reader.hasNext()) {
        containers.putArrayValue(result, _readJsonValue(reader, containers));
      }
      reader.endArray();
      return result;
    case JsonReaderToken.string:
      return reader.nextString();
    case JsonReaderToken.boolean:
      return reader.nextBoolean();
    case JsonReaderToken.nullValue:
      reader.nextNull();
      return containers.jsonNullValue();
    case JsonReaderToken.number:
      return _readJsonNumber(reader.nextString(), containers);
    case JsonReaderToken.endArray:
    case JsonReaderToken.endDocument:
    case JsonReaderToken.endObject:
    case JsonReaderToken.name:
      containers.malformedJson(
        'Expected a JSON value, found ${reader.peek().sourceName}',
      );
  }
}

Object _readJsonNumber<TObject extends Object, TArray extends Object>(
  String literal,
  JsonReaderContainerAdapter<TObject, TArray> containers,
) {
  final integer = BigInt.tryParse(literal);
  final longMin = BigInt.from(-9223372036854775808);
  final longMax = BigInt.from(9223372036854775807);
  if (integer != null && integer >= longMin && integer <= longMax) {
    final value = integer.toInt();
    return JsonIntegerValue(
      value,
      isLong: value < -2147483648 || value > 2147483647,
    );
  }

  final value = double.parse(literal);
  if (!value.isFinite) {
    containers.malformedJson('Non-finite JSON number: $literal');
  }
  return value;
}
