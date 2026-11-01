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
 * Source-derived from StringUtilsTest.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('emptyStringMutableList', () {
    test('has the requested size and empty entries', () {
      expect(emptyStringMutableList(5), ['', '', '', '', '']);
    });

    test('allows replacing entries and changing its size', () {
      final values = emptyStringMutableList(3)..[0] = 'modified';
      values.add('added');

      expect(values, ['modified', '', '', 'added']);
    });

    test('supports zero size and remains growable', () {
      final values = emptyStringMutableList(0);
      expect(values, isEmpty);
      values.add('added');
      expect(values, ['added']);
    });
  });

  group('emptyStringArray', () {
    test('has the requested size and empty entries', () {
      expect(emptyStringArray(5), ['', '', '', '', '']);
    });

    test('allows replacing entries but not changing its size', () {
      final values = emptyStringArray(2)..[0] = 'modified';

      expect(values, ['modified', '']);
      expect(() => values.add('added'), throwsUnsupportedError);
      expect(() => values.removeAt(0), throwsUnsupportedError);
    });

    test('supports zero size and remains fixed length', () {
      final values = emptyStringArray(0);
      expect(values, isEmpty);
      expect(() => values.add('added'), throwsUnsupportedError);
    });
  });
}
