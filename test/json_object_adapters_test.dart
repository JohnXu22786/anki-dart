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
 * Source-derived from JSONObjectTest.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('jsonObjectGetStringOrNull', () {
    test('skips reads for absent keys and JSON null values', () {
      final calls = <String>[];
      final absent = jsonObjectGetStringOrNull(
        key: 'test',
        has: (key) {
          calls.add('has:$key');
          return false;
        },
        isNull: (_) {
          calls.add('isNull');
          return false;
        },
        getString: (_) {
          calls.add('getString');
          return 'unexpected';
        },
      );
      expect(absent, isNull);
      expect(calls, ['has:test']);

      calls.clear();
      final jsonNull = jsonObjectGetStringOrNull(
        key: 'test',
        has: (key) {
          calls.add('has:$key');
          return true;
        },
        isNull: (key) {
          calls.add('isNull:$key');
          return true;
        },
        getString: (_) {
          calls.add('getString');
          return 'unexpected';
        },
      );
      expect(jsonNull, isNull);
      expect(calls, ['has:test', 'isNull:test']);
    });

    test(
      'returns the exact host string and catches only Exception from getter',
      () {
        final calls = <String>[];
        expect(
          jsonObjectGetStringOrNull(
            key: 'test',
            has: (_) {
              calls.add('has');
              return true;
            },
            isNull: (_) {
              calls.add('isNull');
              return false;
            },
            getString: (_) {
              calls.add('getString');
              return 'Android converted value';
            },
          ),
          'Android converted value',
        );
        expect(calls, ['has', 'isNull', 'getString']);
        expect(
          jsonObjectGetStringOrNull(
            key: 'test',
            has: (_) => true,
            isNull: (_) => false,
            getString: (_) => throw const FormatException('not a String'),
          ),
          isNull,
        );

        final error = StateError('not caught by Exception');
        expect(
          () => jsonObjectGetStringOrNull(
            key: 'test',
            has: (_) => true,
            isNull: (_) => false,
            getString: (_) => throw error,
          ),
          throwsA(same(error)),
        );
      },
    );

    test('does not catch failures from presence or null checks', () {
      final error = StateError('presence read failed');
      expect(
        () => jsonObjectGetStringOrNull(
          key: 'test',
          has: (_) => throw error,
          isNull: (_) => false,
          getString: (_) => 'unused',
        ),
        throwsA(same(error)),
      );
    });
  });

  group('jsonObjectIterable', () {
    test('is lazy and reads object values in key order', () {
      final calls = <String>[];
      final iterable = jsonObjectIterable<String>(
        keys: () {
          calls.add('keys');
          return ['1', '2'];
        },
        getJSONObject: (key) {
          calls.add('get:$key');
          return 'object:$key';
        },
      );

      expect(calls, isEmpty);
      expect(iterable.toList(), ['object:1', 'object:2']);
      expect(calls, ['keys', 'get:1', 'get:2']);
    });

    test('obtains fresh keys for each iteration', () {
      var keyReads = 0;
      final iterable = jsonObjectIterable<String>(
        keys: () {
          keyReads++;
          return ['key'];
        },
        getJSONObject: (key) => '$key$keyReads',
      );

      expect(iterable.toList(), ['key1']);
      expect(iterable.toList(), ['key2']);
      expect(keyReads, 2);
    });

    test('propagates a typed object-read failure at its element', () {
      final failure = FormatException('not a JSONObject');
      final iterator = jsonObjectIterable<String>(
        keys: () => ['1', '2'],
        getJSONObject: (key) {
          if (key == '2') throw failure;
          return 'first';
        },
      ).iterator;

      expect(iterator.moveNext(), isTrue);
      expect(iterator.current, 'first');
      expect(() => iterator.moveNext(), throwsA(same(failure)));
    });

    test('supports an empty object', () {
      final iterable = jsonObjectIterable<String>(
        keys: () => const [],
        getJSONObject: (_) => 'unexpected',
      );
      expect(iterable, isEmpty);
    });
  });

  group('JsonObjectHostAdapter cloning and map construction', () {
    test(
      'deepClone clones nested objects and arrays and retains scalar values',
      () {
        final trace = <String>[];
        final innerObject = _TestJsonObject({'leaf': 'value'});
        final array = _TestJsonArray([innerObject, 'opaque']);
        final source = _TestJsonObject({
          'nested': innerObject,
          'items': array,
          'scalar': Object(),
        });
        final scalar = source.values['scalar'];
        var createdObjects = 0;
        var clonedArrays = 0;
        late final JsonObjectHostAdapter<_TestJsonObject, _TestJsonArray>
        adapter;
        adapter = _testJsonObjectAdapter(
          trace,
          createObject: () {
            createdObjects++;
            return _TestJsonObject({});
          },
          cloneArray: (value) {
            clonedArrays++;
            return _TestJsonArray(
              value.values
                  .map(
                    (element) => element is _TestJsonObject
                        ? adapter.deepClone(element)
                        : element,
                  )
                  .toList(),
            );
          },
        );

        final clone = adapter.deepClone(source);

        expect(clone, isNot(same(source)));
        expect(clone.values.keys, ['nested', 'items', 'scalar']);
        expect(clone.values['nested'], isNot(same(innerObject)));
        expect(clone.values['items'], isNot(same(array)));
        expect(
          (clone.values['items']! as _TestJsonArray).values.first,
          isNot(same(innerObject)),
        );
        expect(clone.values['scalar'], same(scalar));
        expect(createdObjects, 3);
        expect(clonedArrays, 1);
        expect(trace.where((call) => call.startsWith('put:')), hasLength(5));
      },
    );

    test(
      'deepClonedInto preserves ordered callback trace and clone identity',
      () {
        final trace = <String>[];
        final source = _TestJsonObject({
          'first': 'scalar',
          'second': _TestJsonObject({'inside': 'nested scalar'}),
          'third': _TestJsonArray(['array value']),
        });
        final clone = _TestJsonSubtype({});
        final adapter = _testJsonObjectAdapter(trace);

        final result = adapter.deepClonedInto(source, clone);

        expect(result, same(clone));
        expect(clone.values.keys, ['first', 'second', 'third']);
        expect(trace, [
          'keys:source',
          'get:first',
          'get:first',
          'put:clone:first',
          'get:second',
          'getJSONObject:second',
          'createObject',
          'keys:source',
          'get:inside',
          'get:inside',
          'put:source:inside',
          'put:clone:second',
          'get:third',
          'getJSONArray:third',
          'cloneArray',
          'put:clone:third',
        ]);
      },
    );

    test('deepClonedInto stops after a failed put and retains exact error', () {
      final trace = <String>[];
      final failure = StateError('put failed');
      final source = _TestJsonObject({'first': 1, 'later': 2});
      final adapter = _testJsonObjectAdapter(
        trace,
        put: (target, key, value) {
          trace.add('put:${target.label}:$key');
          throw failure;
        },
      );

      expect(
        () => adapter.deepClonedInto(
          source,
          _TestJsonObject({}, label: 'target'),
        ),
        throwsA(same(failure)),
      );
      expect(trace, [
        'keys:source',
        'get:first',
        'get:first',
        'put:target:first',
      ]);
    });

    test('deepClone of an empty object creates and returns an empty clone', () {
      final trace = <String>[];
      final adapter = _testJsonObjectAdapter(trace);

      final clone = adapter.deepClone(_TestJsonObject({}));

      expect(clone.values, isEmpty);
      expect(trace, ['createObject', 'keys:source']);
    });

    test('fromMap preserves map order and performs one put for each entry', () {
      final trace = <String>[];
      final adapter = _testJsonObjectAdapter(trace);

      final result = adapter.fromMap({'third': 3, 'first': 1, 'second': 2});

      expect(result.values.keys, ['third', 'first', 'second']);
      expect(trace, [
        'createObject',
        'put:source:third',
        'put:source:first',
        'put:source:second',
      ]);
    });

    test('fromMap creates an empty object for an empty map', () {
      final trace = <String>[];
      final adapter = _testJsonObjectAdapter(trace);

      final result = adapter.fromMap(const {});

      expect(result.values, isEmpty);
      expect(trace, ['createObject']);
    });
  });
}

final class _TestJsonObject {
  _TestJsonObject(this.values, {this.label = 'source'});

  final Map<String, Object?> values;
  final String label;
}

final class _TestJsonSubtype extends _TestJsonObject {
  _TestJsonSubtype(super.values) : super(label: 'clone');
}

final class _TestJsonArray {
  _TestJsonArray(this.values);

  final List<Object?> values;
}

JsonObjectHostAdapter<_TestJsonObject, _TestJsonArray> _testJsonObjectAdapter(
  List<String> trace, {
  _TestJsonObject Function()? createObject,
  _TestJsonArray Function(_TestJsonArray)? cloneArray,
  void Function(_TestJsonObject, String, Object?)? put,
}) => JsonObjectHostAdapter(
  keys: (object) {
    trace.add('keys:${object.label}');
    return object.values.keys;
  },
  get: (object, key) {
    trace.add('get:$key');
    return object.values[key];
  },
  isJsonObject: (value) => value is _TestJsonObject,
  isJsonArray: (value) => value is _TestJsonArray,
  getJsonObject: (object, key) {
    trace.add('getJSONObject:$key');
    return object.values[key]! as _TestJsonObject;
  },
  getJsonArray: (object, key) {
    trace.add('getJSONArray:$key');
    return object.values[key]! as _TestJsonArray;
  },
  deepCloneJsonArray: (array) {
    trace.add('cloneArray');
    return cloneArray?.call(array) ?? _TestJsonArray(List.of(array.values));
  },
  createObject: () {
    trace.add('createObject');
    return createObject?.call() ?? _TestJsonObject({});
  },
  put:
      put ??
      (object, key, value) {
        trace.add('put:${object.label}:$key');
        object.values[key] = value;
      },
);
