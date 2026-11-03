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
 * Behavioral reference: MathJax.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('MathJax.textContainsMathjax', () {
    test('detects a matching inline delimiter pair', () {
      expect(MathJax.textContainsMathjax(r'inline \(x^2\)'), isTrue);
    });

    test('detects a matching display delimiter pair', () {
      expect(MathJax.textContainsMathjax(r'display \[x^2\]'), isTrue);
    });

    test('returns false when an opening or closing delimiter is missing', () {
      expect(MathJax.textContainsMathjax(r'open only \('), isFalse);
      expect(MathJax.textContainsMathjax(r'close only \)'), isFalse);
      expect(MathJax.textContainsMathjax(r'open only \['), isFalse);
      expect(MathJax.textContainsMathjax(r'close only \]'), isFalse);
    });

    test('returns false when the matching close appears first', () {
      expect(MathJax.textContainsMathjax(r'\) then \('), isFalse);
      expect(MathJax.textContainsMathjax(r'\] then \['), isFalse);
    });

    test('does not match an opener with the other delimiter type', () {
      expect(MathJax.textContainsMathjax(r'\( only \]'), isFalse);
      expect(MathJax.textContainsMathjax(r'\[ only \)'), isFalse);
    });

    test('does not require matching delimiter pairs to be nested', () {
      expect(MathJax.textContainsMathjax(r'\( \[ \) \]'), isTrue);
    });

    test('uses the first opening and last closing occurrence', () {
      expect(
        MathJax.textContainsMathjax(r'\(closed\) then unmatched \('),
        isTrue,
      );
    });

    test('returns false for ordinary text', () {
      expect(MathJax.textContainsMathjax('Hello world.'), isFalse);
    });
  });
}
