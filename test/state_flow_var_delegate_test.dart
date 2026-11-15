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
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral reference: MutableStateFlow.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('MutableValue.asVar', () {
    test('retains the host and returns its live value', () {
      final host = _MutableValue<Object>(Object());
      final delegate = host.asVar();

      expect(delegate.getValue(null, null), same(host.value));

      final replacement = Object();
      host.value = replacement;
      expect(delegate.getValue(null, null), same(replacement));

      final secondDelegate = host.asVar();
      expect(secondDelegate, isNot(same(delegate)));
      final sharedReplacement = Object();
      secondDelegate.setValue(null, null, sharedReplacement);
      expect(delegate.getValue(null, null), same(sharedReplacement));
    });

    test(
      'writes the same assigned object once and supports repeated access',
      () {
        final host = _MutableValue<Object>(Object());
        final delegate = host.asVar();
        final first = Object();
        final second = Object();

        delegate.setValue(null, null, first);
        expect(host.value, same(first));
        expect(host.writeCount, 1);
        expect(delegate.getValue(null, null), same(first));

        delegate.setValue(null, null, second);
        expect(host.value, same(second));
        expect(host.writeCount, 2);
        expect(delegate.getValue(null, null), same(second));
      },
    );

    test('ignores receiver and property metadata', () {
      final host = _MutableValue<String>('initial');
      final delegate = host.asVar();

      expect(delegate.getValue(Object(), 'first'), 'initial');
      delegate.setValue(Object(), 'second', 'changed');
      expect(delegate.getValue(Object(), Object()), 'changed');
      expect(host.writeCount, 1);
    });
  });
}

final class _MutableValue<T> implements MutableValue<T> {
  _MutableValue(this._value);

  T _value;
  int writeCount = 0;

  @override
  T get value => _value;

  @override
  set value(T value) {
    writeCount++;
    _value = value;
  }
}
