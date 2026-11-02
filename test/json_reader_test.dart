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
 * Source-derived from JsonReader.kt and JsonReaderTest.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('readJsonObject', () {
    test('recursively reads objects and arrays with source order and null', () {
      final reader = _FakeJsonTokenReader([
        _Token(JsonReaderToken.beginObject),
        _Token(JsonReaderToken.name, 'first'),
        _Token(JsonReaderToken.beginArray),
        _Token(JsonReaderToken.string, 'text'),
        _Token(JsonReaderToken.nullValue),
        _Token(JsonReaderToken.beginObject),
        _Token(JsonReaderToken.name, 'enabled'),
        _Token(JsonReaderToken.boolean, true),
        _Token(JsonReaderToken.endObject),
        _Token(JsonReaderToken.endArray),
        _Token(JsonReaderToken.name, 'last'),
        _Token(JsonReaderToken.beginObject),
        _Token(JsonReaderToken.endObject),
        _Token(JsonReaderToken.name, 'empty'),
        _Token(JsonReaderToken.beginArray),
        _Token(JsonReaderToken.endArray),
        _Token(JsonReaderToken.endObject),
        _Token(JsonReaderToken.endDocument),
      ]);

      final result = readJsonObject(reader, _MapJsonContainerAdapter());

      expect(result.keys, ['first', 'last', 'empty']);
      final values = result['first'] as List<Object?>;
      expect(values[0], 'text');
      expect(values[1], same(jsonReaderNull));
      expect((values[2] as Map<String, Object?>)['enabled'], true);
      expect((result['last'] as Map<String, Object?>).isEmpty, isTrue);
      expect(result['empty'], isEmpty);
      expect(reader.position, 17);
    });

    test('keeps signed integer width and finite decimal/exponent values', () {
      final reader = _FakeJsonTokenReader([
        _Token(JsonReaderToken.beginObject),
        _Token(JsonReaderToken.name, 'intMin'),
        _Token(JsonReaderToken.number, '-2147483648'),
        _Token(JsonReaderToken.name, 'intMax'),
        _Token(JsonReaderToken.number, '2147483647'),
        _Token(JsonReaderToken.name, 'longMin'),
        _Token(JsonReaderToken.number, '-9223372036854775808'),
        _Token(JsonReaderToken.name, 'longMax'),
        _Token(JsonReaderToken.number, '9223372036854775807'),
        _Token(JsonReaderToken.name, 'beyondLong'),
        _Token(JsonReaderToken.number, '9223372036854775808'),
        _Token(JsonReaderToken.name, 'fraction'),
        _Token(JsonReaderToken.number, '1.25'),
        _Token(JsonReaderToken.name, 'exponent'),
        _Token(JsonReaderToken.number, '1e3'),
        _Token(JsonReaderToken.name, 'negativeZero'),
        _Token(JsonReaderToken.number, '-0.0'),
        _Token(JsonReaderToken.endObject),
      ]);

      final result = readJsonObject(reader, _MapJsonContainerAdapter());

      expect(
        result['intMin'],
        const JsonIntegerValue(-2147483648, isLong: false),
      );
      expect(
        result['intMax'],
        const JsonIntegerValue(2147483647, isLong: false),
      );
      expect(
        result['longMin'],
        const JsonIntegerValue(-9223372036854775808, isLong: true),
      );
      expect(
        result['longMax'],
        const JsonIntegerValue(9223372036854775807, isLong: true),
      );
      expect(result['beyondLong'], 9223372036854775808.0);
      expect(result['fraction'], 1.25);
      expect(result['exponent'], 1000.0);
      expect((result['negativeZero'] as double).toString(), '-0.0');
    });

    test('rejects non-objects and trailing values with source messages', () {
      final nonObject = _FakeJsonTokenReader([
        _Token(JsonReaderToken.beginArray),
      ]);
      expect(
        () => readJsonObject(nonObject, _MapJsonContainerAdapter()),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Expected a JSON object',
          ),
        ),
      );
      expect(nonObject.position, 0);

      final trailing = _FakeJsonTokenReader([
        _Token(JsonReaderToken.beginObject),
        _Token(JsonReaderToken.endObject),
        _Token(JsonReaderToken.string, 'trailing'),
      ]);
      expect(
        () => readSingleJsonObject(trailing, _MapJsonContainerAdapter()),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Unexpected data after JSON object',
          ),
        ),
      );
      expect(trailing.position, 2);
    });

    test('propagates parser and container insertion failures unchanged', () {
      final parserFailure = StateError('malformed token stream');
      final brokenReader = _FakeJsonTokenReader([
        _Token(JsonReaderToken.beginObject),
      ], peekFailure: parserFailure);
      expect(
        () => readJsonObject(brokenReader, _MapJsonContainerAdapter()),
        throwsA(same(parserFailure)),
      );

      final putFailure = StateError('container rejected value');
      final reader = _FakeJsonTokenReader([
        _Token(JsonReaderToken.beginObject),
        _Token(JsonReaderToken.name, 'value'),
        _Token(JsonReaderToken.string, 'text'),
        _Token(JsonReaderToken.endObject),
      ]);
      expect(
        () => readJsonObject(
          reader,
          _MapJsonContainerAdapter(putFailure: putFailure),
        ),
        throwsA(same(putFailure)),
      );

      final arrayPutFailure = StateError('array rejected value');
      final arrayReader = _FakeJsonTokenReader([
        _Token(JsonReaderToken.beginObject),
        _Token(JsonReaderToken.name, 'values'),
        _Token(JsonReaderToken.beginArray),
        _Token(JsonReaderToken.string, 'text'),
        _Token(JsonReaderToken.endArray),
        _Token(JsonReaderToken.endObject),
      ]);
      expect(
        () => readJsonObject(
          arrayReader,
          _MapJsonContainerAdapter(arrayPutFailure: arrayPutFailure),
        ),
        throwsA(same(arrayPutFailure)),
      );
    });

    test('rejects non-finite doubles using the exact source message', () {
      final reader = _FakeJsonTokenReader([
        _Token(JsonReaderToken.beginObject),
        _Token(JsonReaderToken.name, 'large'),
        _Token(JsonReaderToken.number, '1e999'),
        _Token(JsonReaderToken.endObject),
      ]);

      expect(
        () => readJsonObject(reader, _MapJsonContainerAdapter()),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Non-finite JSON number: 1e999',
          ),
        ),
      );
    });

    test('reports unexpected values with the source token name', () {
      final reader = _FakeJsonTokenReader([
        _Token(JsonReaderToken.beginObject),
        _Token(JsonReaderToken.name, 'value'),
        _Token(JsonReaderToken.endArray),
      ]);

      expect(
        () => readJsonObject(reader, _MapJsonContainerAdapter()),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Expected a JSON value, found END_ARRAY',
          ),
        ),
      );
    });
  });
}

const Object jsonReaderNull = _JsonNull();

final class _JsonNull {
  const _JsonNull();
}

final class _Token {
  const _Token(this.type, [this.value]);

  final JsonReaderToken type;
  final Object? value;
}

final class _FakeJsonTokenReader implements JsonReaderTokenReader {
  _FakeJsonTokenReader(this.tokens, {this.peekFailure});

  final List<_Token> tokens;
  final Object? peekFailure;
  int position = 0;

  _Token get _current => tokens[position];

  @override
  JsonReaderToken peek() {
    if (peekFailure != null) throw peekFailure!;
    return _current.type;
  }

  void _consume(JsonReaderToken expected) {
    if (peek() != expected) {
      throw StateError('Expected $expected, found ${_current.type}');
    }
    position++;
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
      _current.type != JsonReaderToken.endObject &&
      _current.type != JsonReaderToken.endArray &&
      _current.type != JsonReaderToken.endDocument;

  @override
  String nextName() {
    final value = _current.value as String;
    _consume(JsonReaderToken.name);
    return value;
  }

  @override
  String nextString() {
    final value = _current.value as String;
    final type = _current.type;
    if (type != JsonReaderToken.string && type != JsonReaderToken.number) {
      throw StateError('Expected STRING or NUMBER, found $type');
    }
    _consume(type);
    return value;
  }

  @override
  bool nextBoolean() {
    final value = _current.value as bool;
    _consume(JsonReaderToken.boolean);
    return value;
  }

  @override
  void nextNull() => _consume(JsonReaderToken.nullValue);
}

final class _MapJsonContainerAdapter
    implements JsonReaderContainerAdapter<Map<String, Object?>, List<Object?>> {
  _MapJsonContainerAdapter({this.putFailure, this.arrayPutFailure});

  final Object? putFailure;
  final Object? arrayPutFailure;

  @override
  Map<String, Object?> createObject() => <String, Object?>{};

  @override
  List<Object?> createArray() => <Object?>[];

  @override
  Object jsonNullValue() => jsonReaderNull;

  @override
  void putObjectValue(Map<String, Object?> object, String name, Object? value) {
    if (putFailure != null) throw putFailure!;
    object[name] = value;
  }

  @override
  void putArrayValue(List<Object?> array, Object? value) {
    if (arrayPutFailure != null) throw arrayPutFailure!;
    array.add(value);
  }

  @override
  Never malformedJson(String message) => throw FormatException(message);
}
