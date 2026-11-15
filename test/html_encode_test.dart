/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * Copyright (C) 2006 The Android Open Source Project
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
 * SPDX-FileCopyrightText: 2006 The Android Open Source Project
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from StringUtilsTest.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('htmlEncode', () {
    test('encodes less-than and greater-than characters', () {
      expect(htmlEncode('<'), '&lt;');
      expect(htmlEncode('a<b'), 'a&lt;b');
      expect(htmlEncode('>'), '&gt;');
      expect(htmlEncode('a>b'), 'a&gt;b');
    });

    test('encodes ampersands, apostrophes and quotes', () {
      expect(htmlEncode('&'), '&amp;');
      expect(htmlEncode('a&b'), 'a&amp;b');
      expect(htmlEncode("'"), '&#39;');
      expect(htmlEncode("don't"), 'don&#39;t');
      expect(htmlEncode('"'), '&quot;');
      expect(htmlEncode('"hello"'), '&quot;hello&quot;');
    });

    test('encodes all source special characters in one pass', () {
      expect(htmlEncode("<>&'\""), '&lt;&gt;&amp;&#39;&quot;');
      expect(htmlEncode('&<>'), '&amp;&lt;&gt;');
      expect(htmlEncode('&<>').contains('&amp;lt;'), isFalse);
    });

    test('leaves ordinary, empty, and non-ASCII text unchanged', () {
      expect(htmlEncode('Hello World 123!'), 'Hello World 123!');
      expect(htmlEncode(''), '');
      expect(htmlEncode('😀 e\u0301'), '😀 e\u0301');
    });

    test('encodes special characters inside markup without parsing it', () {
      const input = '<script>alert(\'test & "hack"\')</script>';
      const expected =
          '&lt;script&gt;alert(&#39;test &amp; &quot;hack&quot;&#39;)&lt;/script&gt;';
      expect(htmlEncode(input), expected);
    });
  });
}
