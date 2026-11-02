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
 * Source-derived from JSONArray.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('JsonArrayHostAdapter.deepClone', () {
    test(
      'clones nested arrays and objects but retains opaque scalar identity',
      () {
        final scalar = Object();
        final innerObject = _JsonObject({'value': 7});
        final innerArray = _JsonArray([innerObject, scalar]);
        final rootObject = _JsonObject({'nested': innerArray});
        final source = _JsonArray([rootObject, innerArray, scalar]);
        final adapter = _adapter();

        final clone = adapter.deepClone(source);

        expect(clone, isNot(same(source)));
        expect(clone.values[0], isNot(same(rootObject)));
        final clonedRoot = clone.values[0] as _JsonObject;
        final clonedNested = clonedRoot.values['nested'] as _JsonArray;
        expect(clonedNested, isNot(same(innerArray)));
        expect(clonedNested.values[0], isNot(same(innerObject)));
        expect(clonedNested.values[1], same(scalar));
        expect(clone.values[1], isNot(same(innerArray)));
        expect(clone.values[2], same(scalar));
      },
    );

    test('preserves type-probe, repeated get, typed-read, and put order', () {
      final calls = <String>[];
      final scalar = Object();
      final nested = _JsonArray([]);
      final source = _JsonArray([scalar, nested]);
      final adapter = _adapter(
        calls: calls,
        get: (array, index) {
          calls.add('get:$index');
          return array.values[index];
        },
      );

      adapter.deepClone(source);

      expect(calls, [
        'create',
        'length:2',
        'get:0',
        'isObject',
        'isArray',
        'get:0',
        'put:0',
        'get:1',
        'isObject',
        'isArray',
        'getArray:1',
        'create',
        'length:0',
        'put:1',
      ]);
    });

    test('typed-read failures propagate unchanged and stop before put', () {
      final failure = FormatException('not a JSONArray');
      final calls = <String>[];
      final source = _JsonArray([_JsonArray([])]);
      final adapter = _adapter(
        calls: calls,
        getJsonArray: (_, index) {
          calls.add('getArray:$index');
          throw failure;
        },
      );

      expect(() => adapter.deepClone(source), throwsA(same(failure)));
      expect(calls, contains('getArray:0'));
      expect(calls, isNot(contains('put:0')));
    });
  });

  group('JsonArrayHostAdapter iterators', () {
    test('object and string iterables are lazy and re-iterable', () {
      final calls = <String>[];
      final source = _JsonArray(['first', 'second']);
      final adapter = _adapter(calls: calls);
      final objects = adapter.jsonObjectIterable(source);
      final strings = adapter.stringIterable(source);

      expect(calls, isEmpty);
      expect(strings.toList(), ['first', 'second']);
      expect(strings.toList(), ['first', 'second']);
      expect(calls.where((call) => call.startsWith('getString:')).length, 4);

      calls.clear();
      final objectSource = _JsonArray([
        _JsonObject({'v': 1}),
      ]);
      expect(adapter.jsonObjectIterable(objectSource).toList(), hasLength(1));
      expect(adapter.jsonObjectIterable(objectSource).toList(), hasLength(1));
      expect(calls.where((call) => call.startsWith('getObject:')).length, 2);
      expect(objects, isNotNull);
    });

    test('checks the changing length each time hasNext is called', () {
      final source = _JsonArray(['first']);
      final adapter = _adapter();
      final iterator = adapter.stringIterator(source);

      expect(iterator.hasNext(), isTrue);
      expect(iterator.next(), 'first');
      expect(iterator.hasNext(), isFalse);
      source.values.add('added');
      expect(iterator.hasNext(), isTrue);
      expect(iterator.next(), 'added');
    });

    test(
      'keeps Dart moveNext complete after the array grows at exhaustion',
      () {
        final source = _JsonArray(['first']);
        final iterator = _adapter().stringIterator(source);

        expect(iterator.moveNext(), isTrue);
        expect(iterator.current, 'first');
        expect(iterator.moveNext(), isFalse);
        source.values.add('added');
        expect(iterator.moveNext(), isFalse);
      },
    );

    test('next reads without a hasNext precheck', () {
      final calls = <String>[];
      final source = _JsonArray(['value']);
      final iterator = _adapter(calls: calls).stringIterator(source);

      expect(iterator.next(), 'value');
      expect(calls, ['getString:0']);
    });

    test('failed typed reads propagate and leave the index unchanged', () {
      final failure = FormatException('bad value');
      final calls = <String>[];
      var attempts = 0;
      final iterator = _adapter(
        calls: calls,
        getString: (array, index) {
          calls.add('getString:$index');
          if (attempts++ == 0) throw failure;
          return array.values[index] as String;
        },
      ).stringIterator(_JsonArray(['value']));

      expect(() => iterator.next(), throwsA(same(failure)));
      expect(iterator.next(), 'value');
      expect(calls, ['getString:0', 'getString:0']);
    });

    test('object typed-read failures propagate at the requested index', () {
      final failure = FormatException('not a JSONObject');
      final iterator = _adapter(
        getJsonObject: (_, _) => throw failure,
      ).jsonObjectIterator(_JsonArray([Object()]));

      expect(() => iterator.next(), throwsA(same(failure)));
      expect(iterator.hasNext(), isTrue);
    });
  });

  group('JsonArrayHostAdapter.toStringList', () {
    test('eagerly reads strings in object order and forwards the key', () {
      final calls = <String>[];
      final source = _JsonArray([
        _JsonObject({'name': 'first'}),
        _JsonObject({'name': 'second'}),
      ]);
      final adapter = _adapter(
        calls: calls,
        getObjectString: (object, key) {
          calls.add('getObjectString:$key');
          return object.values[key] as String;
        },
      );

      final result = adapter.toStringList(source, 'name');

      expect(result, ['first', 'second']);
      expect(calls, [
        'length:2',
        'getObject:0',
        'getObjectString:name',
        'length:2',
        'getObject:1',
        'getObjectString:name',
        'length:2',
      ]);
    });

    test('materializes eagerly and propagates a typed string failure', () {
      final failure = FormatException('not a String');
      final calls = <String>[];
      final source = _JsonArray([_JsonObject({}), _JsonObject({})]);
      final adapter = _adapter(
        calls: calls,
        getObjectString: (_, key) {
          calls.add('getObjectString:$key');
          if (calls
                  .where((call) => call.startsWith('getObjectString:'))
                  .length ==
              2) {
            throw failure;
          }
          return 'first';
        },
      );

      expect(() => adapter.toStringList(source, 'key'), throwsA(same(failure)));
      expect(calls, [
        'length:2',
        'getObject:0',
        'getObjectString:key',
        'length:2',
        'getObject:1',
        'getObjectString:key',
      ]);
    });
  });
}

final class _JsonArray {
  _JsonArray(this.values);

  final List<Object?> values;
}

final class _JsonObject {
  _JsonObject(this.values);

  final Map<String, Object?> values;
}

JsonArrayHostAdapter<_JsonArray, _JsonObject> _adapter({
  List<String>? calls,
  Object? Function(_JsonArray, int)? get,
  _JsonObject Function(_JsonArray, int)? getJsonObject,
  _JsonArray Function(_JsonArray, int)? getJsonArray,
  String Function(_JsonArray, int)? getString,
  String Function(_JsonObject, String)? getObjectString,
}) => JsonArrayHostAdapter(
  length: (array) {
    calls?.add('length:${array.values.length}');
    return array.values.length;
  },
  createArray: () {
    calls?.add('create');
    return _JsonArray([]);
  },
  get: get ?? (array, index) => array.values[index],
  isJsonObject: (value) {
    calls?.add('isObject');
    return value is _JsonObject;
  },
  isJsonArray: (value) {
    calls?.add('isArray');
    return value is _JsonArray;
  },
  getJsonObject:
      getJsonObject ??
      (array, index) {
        calls?.add('getObject:$index');
        return array.values[index] as _JsonObject;
      },
  getJsonArray:
      getJsonArray ??
      (array, index) {
        calls?.add('getArray:$index');
        return array.values[index] as _JsonArray;
      },
  deepCloneJsonObject: (object) => _cloneObject(object),
  put: (array, value) {
    calls?.add('put:${array.values.length}');
    array.values.add(value);
  },
  getString:
      getString ??
      (array, index) {
        calls?.add('getString:$index');
        return array.values[index] as String;
      },
  getObjectString:
      getObjectString ??
      (object, key) {
        calls?.add('getObjectString:$key');
        return object.values[key] as String;
      },
);

Object? _cloneValue(Object? value) => switch (value) {
  _JsonArray array => _JsonArray(array.values.map(_cloneValue).toList()),
  _JsonObject object => _cloneObject(object),
  _ => value,
};

_JsonObject _cloneObject(_JsonObject object) => _JsonObject({
  for (final entry in object.values.entries)
    entry.key: _cloneValue(entry.value),
});
