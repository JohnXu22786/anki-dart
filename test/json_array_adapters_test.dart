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
 * Source-derived from JSONArray.kt and PythonExtensions.kt in AnkiDroid
 * 2.25.3; PythonExtensions.kt declares GPL-3.0-or-later without a separate
 * copyright line. See ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('JsonArrayHostAdapter callback compatibility', () {
    test(
      'the old constructor shape still supports helpers without new seams',
      () {
        final calls = <String>[];
        final adapter = _legacyAdapter(calls: calls);
        final first = _JsonObject({'id': 'first'});
        final source = _JsonArray([first]);
        final added = _JsonObject({'id': 'added'});
        final inserted = _JsonObject({'id': 'inserted'});

        adapter.append(source, added);
        adapter.insert(source, 1, inserted);

        expect(source.values, [same(first), same(inserted), same(added)]);
        expect(calls, ['put', 'length:2', 'length:2', 'putAt:2', 'putAt:1']);
        expect(
          () => adapter.index(source, added),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              'JsonArrayHostAdapter.index requires equalsJsonObject.',
            ),
          ),
        );
        expect(calls, ['put', 'length:2', 'length:2', 'putAt:2', 'putAt:1']);
      },
    );

    test('each missing callback fails before its applicable side effects', () {
      final query = _JsonObject({'id': 'query'});

      final indexCalls = <String>[];
      final withoutEquality = _legacyAdapter(calls: indexCalls);
      expect(
        () => withoutEquality.index(_JsonArray([query]), query),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'JsonArrayHostAdapter.index requires equalsJsonObject.',
          ),
        ),
      );
      expect(indexCalls, isEmpty);

      final removeEqualityCalls = <String>[];
      final removeWithoutEquality = _adapter(
        calls: removeEqualityCalls,
        omitEquality: true,
      );
      expect(
        () => removeWithoutEquality.remove(_JsonArray([query]), query),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'JsonArrayHostAdapter.remove requires equalsJsonObject.',
          ),
        ),
      );
      expect(removeEqualityCalls, isEmpty);

      final removeAtCalls = <String>[];
      final removeWithoutRemoveAt = _adapter(
        calls: removeAtCalls,
        omitRemoveAt: true,
        equalsJsonObject: (_, _) {
          removeAtCalls.add('equals');
          return true;
        },
        objectToSourceString: (_) {
          removeAtCalls.add('format');
          return 'query';
        },
      );
      expect(
        () => removeWithoutRemoveAt.remove(_JsonArray([query]), query),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'JsonArrayHostAdapter.remove requires removeAt.',
          ),
        ),
      );
      expect(removeAtCalls, isEmpty);

      final sourceStringCalls = <String>[];
      final removeWithoutSourceString = _adapter(
        calls: sourceStringCalls,
        omitSourceString: true,
        equalsJsonObject: (left, right) {
          sourceStringCalls.add('equals');
          return identical(left, right);
        },
        removeAt: (array, index) {
          sourceStringCalls.add('remove:$index');
          array.values.removeAt(index);
        },
      );
      removeWithoutSourceString.remove(_JsonArray([query]), query);
      expect(sourceStringCalls, [
        'length:1',
        'getObject:0',
        'equals',
        'remove:0',
      ]);
      sourceStringCalls.clear();
      expect(
        () => removeWithoutSourceString.remove(
          _JsonArray([
            _JsonObject({'id': 'other'}),
          ]),
          query,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'JsonArrayHostAdapter.remove requires objectToSourceString when no match is found.',
          ),
        ),
      );
      expect(sourceStringCalls, [
        'length:1',
        'getObject:0',
        'equals',
        'length:1',
      ]);
    });
  });

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

  group('JsonArrayHostAdapter.insert', () {
    test('inserts before front, middle, and end elements', () {
      final adapter = _adapter();
      final first = _JsonObject({'id': 'first'});
      final middle = _JsonObject({'id': 'middle'});
      final last = _JsonObject({'id': 'last'});
      final inserted = _JsonObject({'id': 'inserted'});

      final front = _JsonArray([first, middle, last]);
      adapter.insert(front, 0, inserted);
      expect(front.values, [inserted, first, middle, last]);

      final interior = _JsonArray([first, middle, last]);
      adapter.insert(interior, 1, inserted);
      expect(interior.values, [first, inserted, middle, last]);

      final end = _JsonArray([first, middle, last]);
      adapter.insert(end, 2, inserted);
      expect(end.values, [first, middle, inserted, last]);
    });

    test('appends when index equals or exceeds the initial length', () {
      final calls = <String>[];
      final adapter = _adapter(calls: calls);
      final original = _JsonObject({'id': 'original'});
      final inserted = _JsonObject({'id': 'inserted'});
      final atLength = _JsonArray([original]);
      final beyondLength = _JsonArray([original]);

      adapter.insert(atLength, 1, inserted);
      expect(atLength.values, [original, inserted]);
      expect(calls, ['length:1', 'put:1']);
      calls.clear();

      adapter.insert(beyondLength, 3, inserted);
      expect(beyondLength.values, [original, inserted]);
      expect(calls, ['length:1', 'put:1']);
    });

    test('calls host operations in the source reverse-shift order', () {
      final calls = <String>[];
      final source = _JsonArray([
        _JsonObject({'id': 'a'}),
        _JsonObject({'id': 'b'}),
        _JsonObject({'id': 'c'}),
      ]);
      final inserted = _JsonObject({'id': 'inserted'});

      _adapter(calls: calls).insert(source, 1, inserted);

      expect(calls, [
        'length:3',
        'length:3',
        'getObject:2',
        'putAt:3',
        'getObject:1',
        'putAt:2',
        'putAt:1',
      ]);
    });

    test('typed read failure preserves identity and completed shifts', () {
      final failure = FormatException('not a JSONObject');
      final calls = <String>[];
      final a = _JsonObject({'id': 'a'});
      final bad = Object();
      final c = _JsonObject({'id': 'c'});
      final source = _JsonArray([a, bad, c]);
      final adapter = _adapter(
        calls: calls,
        getJsonObject: (array, index) {
          calls.add('getObject:$index');
          final value = array.values[index];
          if (value is! _JsonObject) throw failure;
          return value;
        },
      );

      expect(
        () => adapter.insert(source, 0, _JsonObject({'id': 'inserted'})),
        throwsA(same(failure)),
      );
      expect(source.values, [a, bad, c, c]);
      expect(calls, [
        'length:3',
        'length:3',
        'getObject:2',
        'putAt:3',
        'getObject:1',
      ]);
    });

    test('passes negative index to host typed read after retaining shifts', () {
      final failure = RangeError.index(-1, const [], 'index');
      final calls = <String>[];
      final first = _JsonObject({'id': 'first'});
      final second = _JsonObject({'id': 'second'});
      final source = _JsonArray([first, second]);
      final adapter = _adapter(
        calls: calls,
        getJsonObject: (array, index) {
          calls.add('getObject:$index');
          if (index < 0) throw failure;
          return array.values[index] as _JsonObject;
        },
      );

      expect(
        () => adapter.insert(source, -1, _JsonObject({'id': 'inserted'})),
        throwsA(same(failure)),
      );
      expect(source.values, [first, first, second]);
      expect(calls, [
        'length:2',
        'length:2',
        'getObject:1',
        'putAt:2',
        'getObject:0',
        'putAt:1',
        'getObject:-1',
      ]);
    });
  });

  group('JsonArrayHostAdapter.append/index/remove', () {
    test('append calls the one-argument host put exactly once', () {
      final calls = <String>[];
      final source = _JsonArray([]);
      final object = _JsonObject({'id': 'value'});
      final adapter = _adapter(
        calls: calls,
        put: (array, value) {
          calls.add('put:${identical(value, object)}');
          array.values.add(value);
        },
      );

      adapter.append(source, object);

      expect(source.values, [same(object)]);
      expect(calls, ['put:true']);
    });

    test(
      'index returns null for empty arrays and first, middle, and last matches',
      () {
        final query = _JsonObject({'id': 'target'});
        final first = _JsonObject({'id': 'target'});
        final middle = _JsonObject({'id': 'target'});
        final last = _JsonObject({'id': 'target'});
        final adapter = _adapter(
          equalsJsonObject: (left, right) =>
              left.values['id'] == right.values['id'],
        );

        expect(adapter.index(_JsonArray([]), query), isNull);
        expect(
          adapter.index(
            _JsonArray([
              first,
              _JsonObject({'id': 'x'}),
            ]),
            query,
          ),
          0,
        );
        expect(
          adapter.index(
            _JsonArray([
              _JsonObject({'id': 'x'}),
              middle,
              _JsonObject({'id': 'x'}),
            ]),
            query,
          ),
          1,
        );
        expect(
          adapter.index(
            _JsonArray([
              _JsonObject({'id': 'x'}),
              last,
            ]),
            query,
          ),
          1,
        );
        expect(
          adapter.index(
            _JsonArray([
              _JsonObject({'id': 'x'}),
            ]),
            query,
          ),
          isNull,
        );
      },
    );

    test('index reads lazily and stops at the first match', () {
      final calls = <String>[];
      final query = _JsonObject({'id': 'query'});
      final first = _JsonObject({'id': 'first'});
      final later = _JsonObject({'id': 'later'});
      final source = _JsonArray([first, later]);
      final adapter = _adapter(
        calls: calls,
        getJsonObject: (array, index) {
          calls.add('read:$index');
          return array.values[index] as _JsonObject;
        },
        equalsJsonObject: (left, right) {
          expect(identical(left, query), isTrue);
          calls.add('equals:${right.values['id']}');
          return right.values['id'] == 'first';
        },
      );

      expect(calls, isEmpty);
      expect(adapter.index(source, query), 0);
      expect(calls, ['length:2', 'read:0', 'equals:first']);
    });

    test('index observes array growth during comparison', () {
      final source = _JsonArray([
        _JsonObject({'id': 'first'}),
      ]);
      var comparisons = 0;
      final target = _JsonObject({'id': 'target'});
      final query = target;
      final adapter = _adapter(
        equalsJsonObject: (left, right) {
          if (comparisons++ == 0) source.values.add(target);
          return identical(left, right);
        },
      );

      expect(adapter.index(source, query), 1);
      expect(comparisons, 2);
    });

    test(
      'index read and equality failures keep identity and stop iteration',
      () {
        final readFailure = FormatException('read failed');
        final readCalls = <String>[];
        final source = _JsonArray([
          _JsonObject({'id': 'first'}),
          _JsonObject({'id': 'later'}),
        ]);
        final readAdapter = _adapter(
          calls: readCalls,
          getJsonObject: (_, index) {
            readCalls.add('read:$index');
            throw readFailure;
          },
          equalsJsonObject: (_, _) {
            readCalls.add('equals');
            return false;
          },
        );

        expect(
          () => readAdapter.index(source, _JsonObject({})),
          throwsA(same(readFailure)),
        );
        expect(readCalls, ['length:2', 'read:0']);

        final equalityFailure = StateError('equality failed');
        final equalityCalls = <String>[];
        final equalityAdapter = _adapter(
          calls: equalityCalls,
          equalsJsonObject: (_, _) {
            equalityCalls.add('equals');
            throw equalityFailure;
          },
        );
        expect(
          () => equalityAdapter.index(source, _JsonObject({})),
          throwsA(same(equalityFailure)),
        );
        expect(equalityCalls, ['length:2', 'getObject:0', 'equals']);
      },
    );

    test(
      'remove removes the first match once after indexing and does not format',
      () {
        final calls = <String>[];
        final query = _JsonObject({'id': 'target'});
        final first = _JsonObject({'id': 'target'});
        final later = _JsonObject({'id': 'target'});
        final source = _JsonArray([first, later]);
        final adapter = _adapter(
          calls: calls,
          equalsJsonObject: (left, right) {
            calls.add('equals:${right.values['id']}');
            return left.values['id'] == right.values['id'];
          },
          removeAt: (array, index) {
            calls.add('remove:$index');
            array.values.removeAt(index);
          },
          objectToSourceString: (_) {
            calls.add('format');
            return 'query';
          },
        );

        adapter.remove(source, query);

        expect(source.values, [same(later)]);
        expect(calls, ['length:2', 'getObject:0', 'equals:target', 'remove:0']);
      },
    );

    test(
      'missing remove formats only after all reads and throws source message',
      () {
        final calls = <String>[];
        final query = _JsonObject({'id': 'missing'});
        final source = _JsonArray([
          _JsonObject({'id': 'first'}),
          _JsonObject({'id': 'second'}),
        ]);
        final adapter = _adapter(
          calls: calls,
          equalsJsonObject: (left, right) {
            calls.add('equals:${right.values['id']}');
            return false;
          },
          removeAt: (_, _) => calls.add('remove'),
          objectToSourceString: (object) {
            calls.add('format');
            return '{"id":"${object.values['id']}"}';
          },
        );

        expect(
          () => adapter.remove(source, query),
          throwsA(
            isA<ArgumentError>().having(
              (error) => error.message,
              'message',
              'Could not find {"id":"missing"}',
            ),
          ),
        );

        expect(calls, [
          'length:2',
          'getObject:0',
          'equals:first',
          'length:2',
          'getObject:1',
          'equals:second',
          'length:2',
          'format',
        ]);
      },
    );

    test(
      'remove read, equality, formatting, and removal failures stop later effects',
      () {
        final query = _JsonObject({'id': 'query'});
        final readFailure = FormatException('read failed');
        final readCalls = <String>[];
        final readAdapter = _adapter(
          calls: readCalls,
          getJsonObject: (_, index) {
            readCalls.add('read:$index');
            throw readFailure;
          },
          removeAt: (_, _) => readCalls.add('remove'),
          objectToSourceString: (_) {
            readCalls.add('format');
            return 'query';
          },
        );
        expect(
          () => readAdapter.remove(_JsonArray([_JsonObject({})]), query),
          throwsA(same(readFailure)),
        );
        expect(readCalls, ['length:1', 'read:0']);

        final equalityFailure = StateError('equality failed');
        final equalityCalls = <String>[];
        final equalityAdapter = _adapter(
          calls: equalityCalls,
          equalsJsonObject: (_, _) {
            equalityCalls.add('equals');
            throw equalityFailure;
          },
          removeAt: (_, _) => equalityCalls.add('remove'),
          objectToSourceString: (_) {
            equalityCalls.add('format');
            return 'query';
          },
        );
        expect(
          () => equalityAdapter.remove(_JsonArray([_JsonObject({})]), query),
          throwsA(same(equalityFailure)),
        );
        expect(equalityCalls, ['length:1', 'getObject:0', 'equals']);

        final formatFailure = StateError('format failed');
        final formatCalls = <String>[];
        final formatAdapter = _adapter(
          calls: formatCalls,
          objectToSourceString: (_) {
            formatCalls.add('format');
            throw formatFailure;
          },
          removeAt: (_, _) => formatCalls.add('remove'),
        );
        expect(
          () => formatAdapter.remove(_JsonArray([]), query),
          throwsA(same(formatFailure)),
        );
        expect(formatCalls, ['length:0', 'format']);

        final removeFailure = StateError('remove failed');
        final removeCalls = <String>[];
        final removeAdapter = _adapter(
          calls: removeCalls,
          equalsJsonObject: (_, _) => true,
          removeAt: (_, index) {
            removeCalls.add('remove:$index');
            throw removeFailure;
          },
          objectToSourceString: (_) {
            removeCalls.add('format');
            return 'query';
          },
        );
        expect(
          () => removeAdapter.remove(_JsonArray([_JsonObject({})]), query),
          throwsA(same(removeFailure)),
        );
        expect(removeCalls, ['length:1', 'getObject:0', 'remove:0']);
      },
    );
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
  void Function(_JsonArray, int, Object?)? putAt,
  void Function(_JsonArray, Object?)? put,
  bool Function(_JsonObject, _JsonObject)? equalsJsonObject,
  void Function(_JsonArray, int)? removeAt,
  String Function(_JsonObject)? objectToSourceString,
  bool omitEquality = false,
  bool omitRemoveAt = false,
  bool omitSourceString = false,
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
  put:
      put ??
      (array, value) {
        calls?.add('put:${array.values.length}');
        array.values.add(value);
      },
  putAt:
      putAt ??
      (array, index, value) {
        calls?.add('putAt:$index');
        if (index == array.values.length) {
          array.values.add(value);
        } else {
          array.values[index] = value;
        }
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
  equalsJsonObject: omitEquality
      ? null
      : equalsJsonObject ?? (left, right) => identical(left, right),
  removeAt: omitRemoveAt
      ? null
      : removeAt ??
            (array, index) {
              calls?.add('remove:$index');
              array.values.removeAt(index);
            },
  objectToSourceString: omitSourceString
      ? null
      : objectToSourceString ?? (object) => object.values.toString(),
);

JsonArrayHostAdapter<_JsonArray, _JsonObject> _legacyAdapter({
  List<String>? calls,
}) => JsonArrayHostAdapter(
  length: (array) {
    calls?.add('length:${array.values.length}');
    return array.values.length;
  },
  createArray: () => _JsonArray([]),
  get: (array, index) => array.values[index],
  isJsonObject: (value) => value is _JsonObject,
  isJsonArray: (value) => value is _JsonArray,
  getJsonObject: (array, index) => array.values[index] as _JsonObject,
  getJsonArray: (array, index) => array.values[index] as _JsonArray,
  deepCloneJsonObject: _cloneObject,
  put: (array, value) {
    calls?.add('put');
    array.values.add(value);
  },
  putAt: (array, index, value) {
    calls?.add('putAt:$index');
    if (index == array.values.length) {
      array.values.add(value);
    } else {
      array.values[index] = value;
    }
  },
  getString: (array, index) => array.values[index] as String,
  getObjectString: (object, key) => object.values[key] as String,
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
