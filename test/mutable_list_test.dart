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
 * Behavioral reference: MutableList.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'dart:collection';

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('MutableList.swapPositions', () {
    test('moves forward through ascending adjacent swaps', () {
      final items = ['a', 'b', 'c', 'd', 'e'];

      items.swapPositions(1, 4);

      expect(items, ['a', 'c', 'd', 'e', 'b']);
    });

    test('moves backward through descending adjacent swaps', () {
      final items = ['a', 'b', 'c', 'd', 'e'];

      items.swapPositions(4, 1);

      expect(items, ['a', 'e', 'b', 'c', 'd']);
    });

    test('same-position moves leave the list unchanged', () {
      final items = ['a', 'b', 'c'];

      items.swapPositions(1, 1);

      expect(items, ['a', 'b', 'c']);
    });

    test(
      'Int.MAX_VALUE equal positions attempt the overflowing backward range',
      () {
        final items = ['a', 'b', 'c'];

        expect(
          () => items.swapPositions(0x7fffffff, 0x7fffffff),
          throwsRangeError,
        );
        expect(items, ['a', 'b', 'c']);
      },
    );

    test('moves the selected position when values repeat', () {
      final items = ['repeat', 'middle', 'repeat', 'last'];

      items.swapPositions(2, 0);

      expect(items, ['repeat', 'repeat', 'middle', 'last']);
    });

    test('each Collections.swap writes the second index before the first', () {
      final items = _RecordingList(['a', 'b', 'c']);

      items.swapPositions(0, 2);

      expect(items.writeOrder, [1, 0, 2, 1]);
    });

    test('out-of-range positions fail when an adjacent swap touches them', () {
      final items = ['a', 'b', 'c'];

      expect(() => items.swapPositions(-1, 1), throwsRangeError);
      expect(items, ['a', 'b', 'c']);
    });

    test(
      'an invalid destination fails only after earlier swaps have applied',
      () {
        final items = ['a', 'b', 'c'];

        expect(() => items.swapPositions(0, 3), throwsRangeError);
        expect(items, ['b', 'c', 'a']);
      },
    );
  });

  group('MutableList.replaceWith', () {
    test('replaces existing values and clears for an empty iterable', () {
      final items = ['old', 'values'];

      items.replaceWith(['new', 'values']);
      expect(items, ['new', 'values']);

      items.replaceWith(const []);
      expect(items, isEmpty);
    });

    test('clears before consuming the same list as the input iterable', () {
      final items = ['first', 'second'];

      items.replaceWith(items);

      expect(items, isEmpty);
    });

    test('keeps yielded values after input iteration throws', () {
      final items = ['old', 'values'];

      expect(() => items.replaceWith(_yieldThenThrow()), throwsStateError);
      expect(items, ['first', 'second']);
    });
  });
}

Iterable<String> _yieldThenThrow() sync* {
  yield 'first';
  yield 'second';
  throw StateError('iteration failed');
}

class _RecordingList<T> extends ListBase<T> {
  _RecordingList(this._items);

  final List<T> _items;
  final List<int> writeOrder = [];

  @override
  int get length => _items.length;

  @override
  set length(int newLength) => _items.length = newLength;

  @override
  T operator [](int index) => _items[index];

  @override
  void operator []=(int index, T value) {
    writeOrder.add(index);
    _items[index] = value;
  }
}
