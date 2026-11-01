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
 * Source-derived from JsonWriter.kt and JsonWriterTest.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('writeJsonObject', () {
    test('preserves nested object and array traversal order', () {
      final sink = _RecordingJsonWriter();
      final array = _HostJsonArray(3, {
        0: 42,
        2: <String, Object?>{'inner': 'value'},
      });
      final source = <String, Object?>{'second': array, 'first': true};

      writeJsonObject(sink, source, _MapJsonWriterAdapter());

      expect(sink.operations, [
        'beginObject',
        'name(second)',
        'beginArray',
        'number(42)',
        'null',
        'beginObject',
        'name(inner)',
        'string(value)',
        'endObject',
        'endArray',
        'name(first)',
        'boolean(true)',
        'endObject',
      ]);
      expect(array.lengthCalls, 1);
      expect(array.optIndices, [0, 1, 2]);
    });

    test('dispatches null, booleans, numbers, and fallback strings', () {
      final sink = _RecordingJsonWriter();
      final number = Object();
      final source = <String, Object?>{
        'null': null,
        'sentinel': jsonNullSentinel,
        'yes': true,
        'no': false,
        'number': number,
        'fallback': _StringFallback('source text'),
      };

      writeJsonObject(sink, source, _MapJsonWriterAdapter(number: number));

      expect(sink.operations, [
        'beginObject',
        'name(null)',
        'null',
        'name(sentinel)',
        'null',
        'name(yes)',
        'boolean(true)',
        'name(no)',
        'boolean(false)',
        'name(number)',
        'number(opaque)',
        'name(fallback)',
        'string(source text)',
        'endObject',
      ]);
      expect(identical(sink.lastNumber, number), isTrue);
    });

    test('propagates callback failure and stops later writes', () {
      final failure = StateError('writer failed');
      final sink = _RecordingJsonWriter(
        failOn: 'name(first)',
        failure: failure,
      );

      expect(
        () => writeJsonObject(sink, <String, Object?>{
          'first': 'value',
          'later': 'unwritten',
        }, _MapJsonWriterAdapter()),
        throwsA(same(failure)),
      );
      expect(sink.operations, ['beginObject', 'name(first)']);
    });
  });
}

final class _RecordingJsonWriter implements JsonWriterSink {
  _RecordingJsonWriter({this.failOn, this.failure});

  final String? failOn;
  final Object? failure;
  final List<String> operations = [];
  Object? lastNumber;

  void _record(String operation) {
    operations.add(operation);
    if (operation == failOn) {
      Error.throwWithStackTrace(failure!, StackTrace.current);
    }
  }

  @override
  void beginObject() => _record('beginObject');

  @override
  void endObject() => _record('endObject');

  @override
  void beginArray() => _record('beginArray');

  @override
  void endArray() => _record('endArray');

  @override
  void name(String name) => _record('name($name)');

  @override
  void nullValue() => _record('null');

  @override
  void valueBoolean(bool value) => _record('boolean($value)');

  @override
  void valueNumber(Object value) {
    lastNumber = value;
    _record(value is num ? 'number($value)' : 'number(opaque)');
  }

  @override
  void valueString(String value) => _record('string($value)');
}

final class _MapJsonWriterAdapter
    implements
        JsonWriterContainerAdapter<Map<String, Object?>, _HostJsonArray> {
  _MapJsonWriterAdapter({this.number});

  final Object? number;

  @override
  Iterable<String> keys(Map<String, Object?> object) => object.keys;

  @override
  Object? get(Map<String, Object?> object, String name) => object[name];

  @override
  bool isJsonNull(Object value) => identical(value, jsonNullSentinel);

  @override
  bool isNumber(Object value) => value is num || identical(value, number);

  @override
  bool isObject(Object value) => value is Map<String, Object?>;

  @override
  Map<String, Object?> asObject(Object value) => value as Map<String, Object?>;

  @override
  bool isArray(Object value) => value is _HostJsonArray;

  @override
  _HostJsonArray asArray(Object value) => value as _HostJsonArray;

  @override
  int arrayLength(_HostJsonArray array) {
    array.lengthCalls++;
    return array.length;
  }

  @override
  Object? arrayOpt(_HostJsonArray array, int index) {
    array.optIndices.add(index);
    return array.values[index];
  }
}

final class _HostJsonArray {
  _HostJsonArray(this.length, this.values);

  final int length;
  final Map<int, Object?> values;
  int lengthCalls = 0;
  final List<int> optIndices = [];
}

final class _StringFallback {
  const _StringFallback(this.text);

  final String text;

  @override
  String toString() => text;
}

final jsonNullSentinel = Object();
