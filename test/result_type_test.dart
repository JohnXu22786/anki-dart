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
 * Source-derived from ResultType.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('ResultType', () {
    test('uses its string value for equality and map keys', () {
      const first = ResultType('bare_field');
      const equal = ResultType('bare_field');
      const different = ResultType('type');
      final results = <ResultType, String>{first: 'selected'};

      expect(first, equal);
      expect(first.hashCode, equal.hashCode);
      expect(first, isNot(different));
      expect(results[equal], 'selected');
    });

    test('returns the underlying string without changing it', () {
      const value = ResultType('  field\n');
      const empty = ResultType('');

      expect(value.toString(), '  field\n');
      expect(empty.toString(), '');
    });

    test('hashes UTF-16 surrogate pairs like Kotlin String', () {
      expect(const ResultType('😊').hashCode, 1772909);
    });

    test('keeps Kotlin signed 32-bit string hash overflow', () {
      final longValue = 'ResultType\u0000${List.filled(64, 'x').join()}';

      expect(ResultType(longValue).hashCode, -300357175);
    });
  });
}
