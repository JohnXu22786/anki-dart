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
 * Source-derived from NamedJSONComparatorTest.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('NamedJSONComparator', () {
    test('returns zero for names equal ignoring case', () {
      final result = NamedJSONComparator.INSTANCE.compare(
        _NamedValue('TestName1'),
        _NamedValue('testname1'),
        compareIgnoreCase: (left, right) =>
            left.toLowerCase().compareTo(right.toLowerCase()),
      );

      expect(result, 0);
    });

    test('orders TestName1 before TestName2', () {
      final result = NamedJSONComparator.INSTANCE.compare(
        _NamedValue('TestName1'),
        _NamedValue('TestName2'),
        compareIgnoreCase: (left, right) =>
            left.toLowerCase().compareTo(right.toLowerCase()),
      );

      expect(result, lessThan(0));
    });

    test('reads each name once in order and returns the exact host result', () {
      final events = <String>[];
      final left = _NamedValue('left', onRead: () => events.add('left'));
      final right = _NamedValue('right', onRead: () => events.add('right'));

      final result = NamedJSONComparator.INSTANCE.compare(
        left,
        right,
        compareIgnoreCase: (leftName, rightName) {
          events.add('compare:$leftName:$rightName');
          return -37;
        },
      );

      expect(result, -37);
      expect(left.reads, 1);
      expect(right.reads, 1);
      expect(events, ['left', 'right', 'compare:left:right']);
    });

    test('propagates getter and host comparator failures unchanged', () {
      final getterFailure = StateError('name failed');
      final events = <String>[];
      final left = _NamedValue('left', onRead: () => events.add('left'));
      final right = _NamedValue(
        'right',
        onRead: () => events.add('right'),
        failure: getterFailure,
      );

      expect(
        () => NamedJSONComparator.INSTANCE.compare(
          left,
          right,
          compareIgnoreCase: (_, _) => fail('unexpected comparator call'),
        ),
        throwsA(same(getterFailure)),
      );
      expect(events, ['left', 'right']);

      final comparatorFailure = StateError('compare failed');
      expect(
        () => NamedJSONComparator.INSTANCE.compare(
          _NamedValue('left'),
          _NamedValue('right'),
          compareIgnoreCase: (_, _) => throw comparatorFailure,
        ),
        throwsA(same(comparatorFailure)),
      );
    });
  });
}

final class _NamedValue implements NamedObject {
  _NamedValue(this.value, {this.onRead, this.failure});

  final String value;
  final void Function()? onRead;
  final Object? failure;
  int reads = 0;

  @override
  String get name {
    reads++;
    onRead?.call();
    if (failure case final failure?) {
      throw failure;
    }
    return value;
  }
}
