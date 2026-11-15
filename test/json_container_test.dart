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
 * Source-derived from JSONContainer.kt and PythonExtensions.kt in AnkiDroid
 * 2.25.3; PythonExtensions.kt declares GPL-3.0-or-later without a separate
 * copyright line. See ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('JSONContainer', () {
    test('extension wrappers forward one opaque object in source order', () {
      final calls = <String>[];
      final source = _JsonArray([]);
      final value = Object();
      final holder = _Holder(value, onRead: () => calls.add('jsonObject'));
      final container = _container(
        source,
        calls: calls,
        append: (array, object) {
          expect(array, same(source));
          expect(object, same(value));
          calls.add('append');
        },
        remove: (array, object) {
          expect(array, same(source));
          expect(object, same(value));
          calls.add('remove');
        },
        index: (array, object) {
          expect(array, same(source));
          expect(object, same(value));
          calls.add('index');
          return 7;
        },
        insert: (array, index, object) {
          expect(array, same(source));
          expect(index, 13);
          expect(object, same(value));
          calls.add('insert');
        },
      );

      container.append(holder);
      container.remove(holder);
      expect(container.index(holder), 7);
      container.insert(13, holder);

      expect(calls, [
        'jsonObject',
        'append',
        'jsonObject',
        'remove',
        'jsonObject',
        'index',
        'jsonObject',
        'insert',
      ]);
    });

    test('index maps absent and present Optional results to nullable ints', () {
      final source = _JsonArray([]);
      var result = _container(source, index: (_, _) => null);
      expect(result.index(_Holder(Object())), isNull);

      result = _container(source, index: (_, _) => 0);
      expect(result.index(_Holder(Object())), 0);
    });

    test('holder getter failure prevents the host operation', () {
      final failure = FormatException('holder unavailable');
      var operations = 0;
      final container = _container(
        _JsonArray([]),
        append: (_, _) => operations++,
        remove: (_, _) => operations++,
        index: (_, _) {
          operations++;
          return null;
        },
        insert: (_, _, _) => operations++,
      );
      final holder = _Holder(Object(), onRead: () => throw failure);

      expect(() => container.append(holder), throwsA(same(failure)));
      expect(() => container.remove(holder), throwsA(same(failure)));
      expect(() => container.index(holder), throwsA(same(failure)));
      expect(() => container.insert(0, holder), throwsA(same(failure)));
      expect(operations, 0);
    });

    test('each host operation failure preserves identity', () {
      final failure = StateError('host operation failed');
      final calls = <String>[];
      final container = _container(
        _JsonArray([]),
        calls: calls,
        append: (_, _) {
          calls.add('append');
          throw failure;
        },
        remove: (_, _) {
          calls.add('remove');
          throw failure;
        },
        index: (_, _) {
          calls.add('index');
          throw failure;
        },
        insert: (_, _, _) {
          calls.add('insert');
          throw failure;
        },
      );
      final holder = _Holder(Object(), onRead: () => calls.add('jsonObject'));

      expect(() => container.append(holder), throwsA(same(failure)));
      expect(calls, ['jsonObject', 'append']);
      calls.clear();
      expect(() => container.remove(holder), throwsA(same(failure)));
      expect(calls, ['jsonObject', 'remove']);
      calls.clear();
      expect(() => container.index(holder), throwsA(same(failure)));
      expect(calls, ['jsonObject', 'index']);
      calls.clear();
      expect(() => container.insert(4, holder), throwsA(same(failure)));
      expect(calls, ['jsonObject', 'insert']);
    });

    test('maps host iterator lazily as each value is demanded', () {
      final calls = <String>[];
      final source = _JsonArray([Object(), Object()]);
      final container = _container(
        source,
        calls: calls,
        constructor: (jsonObject) {
          calls.add('construct:${source.values.indexOf(jsonObject)}');
          return _Holder(jsonObject);
        },
      );

      final iterator = container.iterator;
      expect(calls, ['iterator']);
      expect(iterator.moveNext(), isTrue);
      expect(calls, ['iterator', 'construct:0']);
      expect(iterator.current.jsonObject, same(source.values[0]));
      expect(iterator.moveNext(), isTrue);
      expect(calls, ['iterator', 'construct:0', 'construct:1']);
      expect(iterator.current.jsonObject, same(source.values[1]));
      expect(iterator.moveNext(), isFalse);
      expect(calls, ['iterator', 'construct:0', 'construct:1']);
    });

    test(
      'keeps the original constructor usable without extension callbacks',
      () {
        final source = _JsonArray([Object()]);
        final container = JSONContainer<_JsonArray, _Holder>(
          jsonArray: source,
          constructor: _Holder.new,
          jsonObjectIterator: (array) => array.values.iterator,
          getJsonObject: (array, index) => array.values[index],
          put: (_, _, _) {},
          length: (array) => array.values.length,
        );

        expect(container.length, 1);
        var getterCalls = 0;
        final holder = _Holder(
          Object(),
          onRead: () {
            getterCalls++;
            throw FormatException('holder unavailable');
          },
        );
        expect(() => container.append(holder), throwsA(isA<StateError>()));
        expect(getterCalls, 0);
      },
    );

    test('get and set forward the exact index and opaque object once', () {
      final calls = <String>[];
      final source = _JsonArray([Object(), Object()]);
      final replacement = Object();
      final container = _container(source, calls: calls);

      final result = container[1];
      expect(result.jsonObject, same(source.values[1]));
      expect(calls, ['get:1', 'construct']);

      calls.clear();
      final holder = _Holder(replacement, onRead: () => calls.add('holder'));
      container[7] = holder;
      expect(calls, ['holder', 'put:7']);
      expect(source.lastPutIndex, 7);
      expect(source.lastPutValue, same(replacement));
    });

    test('get and set propagate the original host failures', () {
      final readFailure = FormatException('typed read failed');
      final source = _JsonArray([Object()]);
      final container = _container(
        source,
        getJsonObject: (_, index) {
          expect(index, 4);
          throw readFailure;
        },
      );
      expect(() => container[4], throwsA(same(readFailure)));

      final putFailure = StateError('put failed');
      final writeContainer = _container(
        source,
        put: (_, index, value) {
          expect(index, 6);
          expect(value, same(source.values.single));
          throw putFailure;
        },
      );
      expect(
        () => writeContainer[6] = _Holder(source.values.single),
        throwsA(same(putFailure)),
      );
    });

    test('length and size each make one host length call', () {
      final calls = <String>[];
      final container = _container(
        _JsonArray([Object(), Object()]),
        calls: calls,
      );

      expect(container.length, 2);
      expect(calls, ['length']);
      calls.clear();
      expect(container.size, 2);
      expect(calls, ['length']);
    });

    test('indices eagerly constructs all values before returning indices', () {
      final calls = <String>[];
      final source = _JsonArray([Object(), Object(), Object()]);
      final container = _container(
        source,
        calls: calls,
        constructor: (jsonObject) {
          calls.add('construct:${source.values.indexOf(jsonObject)}');
          return _Holder(jsonObject);
        },
      );

      final indices = container.indices;

      expect(indices, [0, 1, 2]);
      expect(calls, ['iterator', 'construct:0', 'construct:1', 'construct:2']);
    });

    test('indices propagates an eager constructor failure', () {
      final calls = <int>[];
      final failure = FormatException('cannot construct second element');
      final source = _JsonArray([Object(), Object(), Object()]);
      final container = _container(
        source,
        constructor: (jsonObject) {
          final index = source.values.indexOf(jsonObject);
          calls.add(index);
          if (index == 1) throw failure;
          return _Holder(jsonObject);
        },
      );

      expect(() => container.indices, throwsA(same(failure)));
      expect(calls, [0, 1]);
    });
  });
}

JSONContainer<_JsonArray, _Holder> _container(
  _JsonArray source, {
  List<String>? calls,
  _Holder Function(Object jsonObject)? constructor,
  Object Function(_JsonArray array, int index)? getJsonObject,
  void Function(_JsonArray array, int index, Object value)? put,
  void Function(_JsonArray array, Object value)? append,
  void Function(_JsonArray array, Object value)? remove,
  int? Function(_JsonArray array, Object value)? index,
  void Function(_JsonArray array, int index, Object value)? insert,
}) => JSONContainer<_JsonArray, _Holder>(
  jsonArray: source,
  constructor:
      constructor ??
      (jsonObject) {
        calls?.add('construct');
        return _Holder(jsonObject);
      },
  jsonObjectIterator: (array) {
    calls?.add('iterator');
    return array.values.iterator;
  },
  getJsonObject:
      getJsonObject ??
      (array, index) {
        calls?.add('get:$index');
        return array.values[index];
      },
  put:
      put ??
      (array, index, value) {
        calls?.add('put:$index');
        array.lastPutIndex = index;
        array.lastPutValue = value;
      },
  append:
      append ??
      (array, value) {
        calls?.add('append');
      },
  remove:
      remove ??
      (array, value) {
        calls?.add('remove');
      },
  index:
      index ??
      (array, value) {
        calls?.add('index');
        return null;
      },
  insert:
      insert ??
      (array, index, value) {
        calls?.add('insert:$index');
      },
  length: (array) {
    calls?.add('length');
    return array.values.length;
  },
);

final class _JsonArray {
  _JsonArray(this.values);

  final List<Object> values;
  int? lastPutIndex;
  Object? lastPutValue;
}

final class _Holder implements JSONObjectHolder {
  _Holder(this._jsonObject, {void Function()? onRead}) : _onRead = onRead;

  final Object _jsonObject;
  final void Function()? _onRead;

  @override
  Object get jsonObject {
    _onRead?.call();
    return _jsonObject;
  }
}
