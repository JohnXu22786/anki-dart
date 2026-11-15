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
 * Source-derived from MapUtil.kt and MapUtilTest.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

class _EqualityProbe {
  const _EqualityProbe(this.result);

  final bool result;

  @override
  bool operator ==(Object other) => result && other is _EqualityProbe;

  @override
  int get hashCode => result.hashCode;
}

void main() {
  group('getKeyByValue', () {
    test('returns the corresponding key or null when absent', () {
      final map = {12: 'Anki', 5: 'AnkiMobile', 20: 'AnkiDroid'};

      expect(getKeyByValue(map, 'AnkiDroid'), 20);
      expect(getKeyByValue(map, 'missing'), isNull);
    });

    test('keeps the first matching entry and matches nullable values', () {
      final duplicates = {'first': 'same', 'second': 'same'};
      final nullableValues = <String?, String?>{
        'first-null': null,
        'second-null': null,
      };

      expect(getKeyByValue(duplicates, 'same'), 'first');
      expect(getKeyByValue(nullableValues, null), 'first-null');
      expect(
        getKeyByValue(<String?, String?>{null: 'matched'}, 'matched'),
        isNull,
      );
      expect(getKeyByValue(<String, String?>{'key': null}, 'missing'), isNull);
    });

    test('compares requested value to the entry value in that direction', () {
      final map = {'key': const _EqualityProbe(false)};

      expect(getKeyByValue(map, const _EqualityProbe(true)), 'key');
    });
  });
}
