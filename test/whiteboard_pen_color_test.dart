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
 * Source-derived contract cases for AnkiDroid's WhiteboardPenColor.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('WhiteboardPenColor', () {
    test('selects light or dark preference using the host theme value', () {
      final color = WhiteboardPenColor(0x123456, 0x654321);

      expect(color.fromPreferences(isNightTheme: false), 0x123456);
      expect(color.fromPreferences(isNightTheme: true), 0x654321);
    });

    test('keeps nullable preference values unchanged in either theme', () {
      final lightNull = WhiteboardPenColor(null, 0x654321);
      final darkNull = WhiteboardPenColor(0x123456, null);
      final bothNull = WhiteboardPenColor(null, null);

      expect(lightNull.fromPreferences(isNightTheme: false), isNull);
      expect(lightNull.fromPreferences(isNightTheme: true), 0x654321);
      expect(darkNull.fromPreferences(isNightTheme: false), 0x123456);
      expect(darkNull.fromPreferences(isNightTheme: true), isNull);
      expect(bothNull.fromPreferences(isNightTheme: false), isNull);
      expect(bothNull.fromPreferences(isNightTheme: true), isNull);
    });

    test('default access creates distinct identity-equal instances', () {
      final first = WhiteboardPenColor.defaultColor;
      final second = WhiteboardPenColor.defaultColor;

      expect(first.lightPenColor, isNull);
      expect(first.darkPenColor, isNull);
      expect(second.lightPenColor, isNull);
      expect(second.darkPenColor, isNull);
      expect(first, isNot(same(second)));
      expect(first, isNot(equals(second)));
    });
  });
}
