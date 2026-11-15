/*
 * Copyright (c) 2011 Norbert Nagold <norbert.nagold@gmail.com>
 * Copyright (c) 2014 Houssam Salem <houssam.salem.au@gmail.com>
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
 * SPDX-FileCopyrightText: 2011 Norbert Nagold
 * SPDX-FileCopyrightText: 2014 Houssam Salem
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived adapter contract tests for Note.setField; see
 * ANKIIDROID_UPSTREAM.md for the absence of direct upstream tests.
 */

import 'dart:collection';

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('LibAnki Note.setField', () {
    test('forwards the exact index and value to one indexed setter call', () {
      final fields = _HostFields(['Front', 'Back']);

      libankiNoteSetField(1, 'Updated back', fields: fields);

      expect(fields.setterCalls, [(1, 'Updated back')]);
    });

    test('mutates the backing fields list at the selected index', () {
      final values = ['Front', 'Back'];
      final fields = _HostFields(values);

      libankiNoteSetField(0, 'Updated front', fields: fields);

      expect(values, ['Updated front', 'Back']);
    });

    test('propagates the exact host indexed-setter exception unchanged', () {
      final failure = StateError('host setter failed');
      final fields = _HostFields(['Front'], failure: failure);

      expect(
        () => libankiNoteSetField(0, 'Updated front', fields: fields),
        throwsA(same(failure)),
      );
      expect(fields.setterCalls, [(0, 'Updated front')]);
    });
  });
}

final class _HostFields extends ListBase<String> {
  _HostFields(this.values, {this.failure});

  final List<String> values;
  final Object? failure;
  final setterCalls = <(int, String)>[];

  @override
  int get length => values.length;

  @override
  set length(int value) => values.length = value;

  @override
  String operator [](int index) => values[index];

  @override
  void operator []=(int index, String value) {
    setterCalls.add((index, value));
    if (failure case final error?) throw error;
    values[index] = value;
  }
}
