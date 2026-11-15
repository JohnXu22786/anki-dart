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
 * Source-derived from PythonExtensions.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('PythonExtensions collection helpers', () {
    test('append and extend keep order and preserve partial iteration', () {
      final values = <int>[];
      appendToList(values, 1);
      extendList(values, [2, 3]);
      expect(values, [1, 2, 3]);

      extendList(values, values);
      expect(values, [1, 2, 3, 1, 2, 3]);

      expect(
        () => extendList(values, _valuesThenThrow([4, 5])),
        throwsA(same(_iterationFailure)),
      );
      expect(values, [1, 2, 3, 1, 2, 3, 4, 5]);
    });

    test('sequence length consumes once and wraps at Kotlin Int width', () {
      var iteratorCreations = 0;
      final values = Iterable<int>.generate(3, (index) => index).map((value) {
        iteratorCreations++;
        return value;
      });

      expect(sequenceLength(values), 3);
      expect(iteratorCreations, 3);
      expect(kotlinCountToLong(0x80000000), -0x80000000);
      expect(kotlinCountToLong(0xffffffff), -1);
    });

    test('length helpers use their respective list and host callbacks', () {
      expect(listLength([1, 2, 3]), 3);

      final calls = <String>[];
      expect(
        jsonArrayLength<Object>(
          'array',
          length: (array) {
            calls.add('array:$array');
            return 7;
          },
        ),
        7,
      );
      final container = JSONContainer<String, _Holder>(
        jsonArray: 'container',
        constructor: (_) => _Holder(),
        jsonObjectIterator: (_) => <Object>[].iterator,
        getJsonObject: (_, _) => Object(),
        put: (_, _, _) {},
        length: (value) {
          calls.add('container:$value');
          return 9;
        },
      );
      expect(jsonContainerLength(container), 9);
      expect(calls, ['array:array', 'container:container']);
    });

    test(
      'pop mutates and lets the host map invalid indices to its exception',
      () {
        final values = ['a', 'b', 'c'];
        expect(popFromList(values, 1), 'b');
        expect(values, ['a', 'c']);

        final failure = StateError('host index failure');
        final invalidCalls = <int>[];
        T removeAt<T>(List<T> list, int index) {
          invalidCalls.add(index);
          throw failure;
        }

        expect(
          () => popFromList(values, -1, removeAt: removeAt),
          throwsA(same(failure)),
        );
        expect(
          () => popFromList(values, values.length, removeAt: removeAt),
          throwsA(same(failure)),
        );
        expect(invalidCalls, [-1, 2]);
        expect(values, ['a', 'c']);
      },
    );

    test('items materializes host entries in their iteration order', () {
      final visits = <String>[];
      final result = hashMapItems<String, int>(
        <String, int>{},
        entries: (_) {
          return [MapEntry('second', 2), MapEntry('first', 1)].map((entry) {
            visits.add(entry.key);
            return entry;
          });
        },
      );

      expect(visits, ['second', 'first']);
      expect(result, [('second', 2), ('first', 1)]);
    });

    test(
      'nullable list emptiness handles null, empty, and nonempty inputs',
      () {
        expect(listIsNullOrEmpty<int>(null), isTrue);
        expect(listIsNullOrEmpty<int>([]), isTrue);
        expect(listIsNullOrEmpty([0]), isFalse);
      },
    );

    test(
      'vararg list keeps the nested array quirk; collection list copies',
      () {
        final arguments = <String>['a', 'b'];
        final varargResult = listFromVarargs(arguments);
        expect(varargResult, hasLength(1));
        expect(varargResult.single, same(arguments));

        final source = <String>['a', 'b'];
        final copied = listFromCollection(source);
        expect(copied, ['a', 'b']);
        expect(copied, isNot(same(source)));
        source.add('c');
        expect(copied, ['a', 'b']);
        copied.add('d');
        expect(source, ['a', 'b', 'c']);
      },
    );

    test('set copies values and removes duplicates', () {
      final source = <int>[2, 1, 2, 3, 1];
      final result = setFromList(source);
      expect(result, {1, 2, 3});
      expect(result.length, 3);
      source.add(4);
      expect(result, isNot(contains(4)));
    });

    test('join uses this string as separator and keeps iterable order', () {
      expect(joinStrings(' / ', ['one', 'two', 'three']), 'one / two / three');
      expect(joinStrings(',', <String>[]), '');
      expect(joinStrings(',', ['']), '');
    });

    test('toJsonArray creates once and keeps puts before a host failure', () {
      final calls = <String>[];
      final result = listToJsonArray<int, List<int>>(
        [1, 2],
        createArray: () {
          calls.add('create');
          return <int>[];
        },
        put: (array, value) {
          calls.add('put:$value');
          array.add(value as int);
        },
      );

      expect(result, [1, 2]);
      expect(calls, ['create', 'put:1', 'put:2']);
      List<int>? failedArray;
      expect(
        () => listToJsonArray<int, List<int>>(
          [1, 2, 3],
          createArray: () {
            failedArray = <int>[];
            return failedArray!;
          },
          put: (array, value) {
            calls.add('failed-put:$value');
            if (value == 3) throw _putFailure;
            array.add(value as int);
          },
        ),
        throwsA(same(_putFailure)),
      );
      expect(failedArray, [1, 2]);
      expect(calls, [
        'create',
        'put:1',
        'put:2',
        'failed-put:1',
        'failed-put:2',
        'failed-put:3',
      ]);
    });
  });
}

final _iterationFailure = StateError('iteration failed');
final _putFailure = StateError('put failed');

final class _Holder implements JSONObjectHolder {
  @override
  Object get jsonObject => Object();
}

Iterable<T> _valuesThenThrow<T>(List<T> values) sync* {
  yield* values;
  throw _iterationFailure;
}
