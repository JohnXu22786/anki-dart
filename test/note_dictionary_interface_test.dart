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
 */

import 'dart:collection';

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('LibAnki Note dictionary interface', () {
    test('keys preserve field map iteration order', () {
      final fieldMap = {'Back': 1, 'Front': 0};

      expect(libankiNoteKeys(fieldMap: () => fieldMap), ['Back', 'Front']);
    });

    test('uninitialized field map propagates the host exception unchanged', () {
      final failure = _HostNullPointerException();
      final inaccessibleFields = _InaccessibleFields();
      final resolves = <String>[];

      Map<String, int> missingMap(String caller) {
        resolves.add(caller);
        throw failure;
      }

      expect(
        () => libankiNoteKeys(fieldMap: () => missingMap('keys')),
        throwsA(same(failure)),
      );
      expect(
        () => libankiNoteItems(
          fieldMap: () => missingMap('items'),
          fields: inaccessibleFields,
        ),
        throwsA(same(failure)),
      );
      expect(
        () => libankiNoteFieldIndex(
          'Front',
          fieldMap: () => missingMap('fieldIndex'),
          illegalArgumentException: (_) => _HostIllegalArgumentException(),
        ),
        throwsA(same(failure)),
      );
      expect(
        () => libankiNoteGetItem(
          'Front',
          fieldMap: () => missingMap('getItem'),
          fields: inaccessibleFields,
          illegalArgumentException: (_) => _HostIllegalArgumentException(),
        ),
        throwsA(same(failure)),
      );
      expect(
        () => libankiNoteSetItem(
          'Front',
          'value',
          fieldMap: () => missingMap('setItem'),
          fields: inaccessibleFields,
          illegalArgumentException: (_) => _HostIllegalArgumentException(),
        ),
        throwsA(same(failure)),
      );
      expect(
        () => libankiNoteContains(
          'Front',
          fieldMap: () => missingMap('contains'),
        ),
        throwsA(same(failure)),
      );
      expect(resolves, [
        'keys',
        'items',
        'fieldIndex',
        'getItem',
        'setItem',
        'contains',
      ]);
      expect(inaccessibleFields.accesses, 0);
    });

    test('values returns the exact mutable fields list', () {
      final fields = ['question', 'answer'];

      final values = libankiNoteValues(fields: fields);
      values[0] = 'changed';

      expect(values, same(fields));
      expect(fields, ['changed', 'answer']);
    });

    test('items places rows by ordinal while preserving the source TODO', () {
      final fieldMap = {'Back': 1, 'Front': 0};
      final fields = ['question', 'answer'];

      expect(libankiNoteItems(fieldMap: () => fieldMap, fields: fields), [
        ['Front', 'question'],
        ['Back', 'answer'],
      ]);
    });

    test('missing field lookup constructs the exact host exception', () {
      final failure = _HostIllegalArgumentException();
      final messages = <String>[];

      expect(
        () => libankiNoteFieldIndex(
          'Missing',
          fieldMap: () => {'Front': 0},
          illegalArgumentException: (message) {
            messages.add(message);
            return failure;
          },
        ),
        throwsA(same(failure)),
      );
      expect(messages, ["No field named 'Missing' found"]);
    });

    test('get and set resolve the field before accessing fields', () {
      for (final set in [false, true]) {
        final failure = _HostIllegalArgumentException();
        final fields = _InaccessibleFields();
        var exceptionCalls = 0;

        expect(() {
          if (set) {
            libankiNoteSetItem(
              'Missing',
              'value',
              fieldMap: () => {'Front': 0},
              fields: fields,
              illegalArgumentException: (_) {
                exceptionCalls++;
                return failure;
              },
            );
          } else {
            libankiNoteGetItem(
              'Missing',
              fieldMap: () => {'Front': 0},
              fields: fields,
              illegalArgumentException: (_) {
                exceptionCalls++;
                return failure;
              },
            );
          }
        }, throwsA(same(failure)));
        expect(exceptionCalls, 1);
        expect(fields.accesses, 0);
      }
    });

    test('get and set read and write the resolved ordinal', () {
      final fieldMap = {'Back': 1, 'Front': 0};
      final fields = ['question', 'answer'];

      expect(
        libankiNoteGetItem(
          'Back',
          fieldMap: () => fieldMap,
          fields: fields,
          illegalArgumentException: _unexpectedException,
        ),
        'answer',
      );
      libankiNoteSetItem(
        'Front',
        'updated',
        fieldMap: () => fieldMap,
        fields: fields,
        illegalArgumentException: _unexpectedException,
      );
      expect(fields, ['updated', 'answer']);
    });

    test('contains delegates to map membership without reading a value', () {
      final fieldMap = _MembershipOnlyMap({'Front': 0});

      expect(libankiNoteContains('Front', fieldMap: () => fieldMap), isTrue);
      expect(fieldMap.membershipChecks, ['Front']);
      expect(fieldMap.valueReads, 0);
    });
  });
}

Object _unexpectedException(String message) =>
    StateError('Unexpected missing field: $message');

final class _HostIllegalArgumentException implements Exception {}

final class _HostNullPointerException implements Exception {}

final class _InaccessibleFields extends ListBase<String> {
  int accesses = 0;

  @override
  int get length => 0;

  @override
  set length(int value) => throw StateError('Unexpected length write');

  @override
  String operator [](int index) {
    accesses++;
    throw StateError('Unexpected field read');
  }

  @override
  void operator []=(int index, String value) {
    accesses++;
    throw StateError('Unexpected field write');
  }
}

final class _MembershipOnlyMap extends MapBase<String, int> {
  _MembershipOnlyMap(this._values);

  final Map<String, int> _values;
  final List<String> membershipChecks = [];
  int valueReads = 0;

  @override
  int? operator [](Object? key) {
    valueReads++;
    throw StateError('Unexpected field map value read');
  }

  @override
  void operator []=(String key, int value) => _values[key] = value;

  @override
  void clear() => _values.clear();

  @override
  Iterable<String> get keys => _values.keys;

  @override
  int get length => _values.length;

  @override
  bool containsKey(Object? key) {
    membershipChecks.add(key as String);
    return _values.containsKey(key);
  }

  @override
  int? remove(Object? key) => _values.remove(key);
}
