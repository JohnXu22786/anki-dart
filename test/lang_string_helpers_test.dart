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
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral reference: Lang.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('withoutUnicodeIsolation', () {
    test(
      'removes repeated isolation markers and preserves surrounding text',
      () {
        expect(
          withoutUnicodeIsolation('a\u2068b\u2069c\u2068d\u2069e'),
          'abcde',
        );
      },
    );
  });

  group('withCollapsedWhitespace', () {
    test('replaces the exact literal backslash-s-plus token', () {
      expect(withCollapsedWhitespace(r'a\s+b\s+c'), 'a b c');
    });

    test('leaves ordinary spaces, tabs, and newlines unchanged', () {
      const input = 'a  b\t c\n d';
      expect(withCollapsedWhitespace(input), input);
    });

    test('leaves other regex-like tokens unchanged', () {
      const input = r'\s \S+ \d+ .+ [a-z]';
      expect(withCollapsedWhitespace(input), input);
    });
  });
}
