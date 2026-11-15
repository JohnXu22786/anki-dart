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
 * Source-derived from NotetypeJson.kt and NoteTypeTest.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('nonEmptyFields', () {
    test('matches the direct upstream NoteTypeTest cases', () {
      final fieldNames = ['Front', 'Back'];
      final expected = <String>{};

      expect(nonEmptyFields(fieldNames, ['', '']), expected);
      expected.add('Front');
      expect(nonEmptyFields(fieldNames, ['<br/>', '   \t ']), expected);
      expect(nonEmptyFields(fieldNames, ['P', '']), expected);
      expected.add('Back');
      expect(nonEmptyFields(fieldNames, ['P', 'A']), expected);
    });

    test('truncates extra values or field names like Kotlin zip', () {
      expect(nonEmptyFields(['Front'], ['P', 'A']), {'Front'});
      expect(nonEmptyFields(['Front', 'Back'], ['P']), {'Front'});
    });

    test('collapses repeated field names into a set', () {
      final result = nonEmptyFields(['Repeated', 'Repeated'], ['one', 'two']);

      expect(result, {'Repeated'});
      result.add('Mutable');
      expect(result, {'Repeated', 'Mutable'});
    });

    test('uses Kotlin/JVM whitespace trimming for values', () {
      expect(
        nonEmptyFields(
          ['Whitespace', 'NextLineWhitespace', 'NotKotlinWhitespace'],
          ['\u00a0\u3000', '\u001c\u000b', '\u0085'],
        ),
        {'NotKotlinWhitespace'},
      );
    });

    test('counts literal markup as nonempty content', () {
      expect(nonEmptyFields(['Front'], ['<br/>']), {'Front'});
    });
  });
}
