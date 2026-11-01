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
 * Source-derived from SearchString.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('SearchString', () {
    test('uses the wrapped string for value equality and hash semantics', () {
      final first = SearchString.fromValidatedBackendSearchString('deck:one');
      final equal = SearchString.fromValidatedBackendSearchString('deck:one');
      final different = SearchString.fromValidatedBackendSearchString(
        'deck:two',
      );
      final values = <SearchString, String>{first: 'selected'};

      expect(first, equal);
      expect(first.hashCode, equal.hashCode);
      expect(first, isNot(different));
      expect(values[equal], 'selected');
      expect(
        SearchString.fromValidatedBackendSearchString('😊').hashCode,
        1772909,
      );
    });

    test(
      'projects a backend-built value without parsing or normalizing it',
      () {
        const backendValue = '  is:due   tag:"two words"\n';
        final search = SearchString.fromValidatedBackendSearchString(
          backendValue,
        );

        expect(search.value, backendValue);
        expect(search.toString(), backendValue);
      },
    );

    test('uses UTF-16 code-unit length and exposes EMPTY', () {
      expect(SearchString.fromValidatedBackendSearchString('a😊').length, 3);
      expect(SearchString.EMPTY.value, '');
      expect(SearchString.EMPTY.length, 0);
      expect(SearchString.EMPTY.toString(), '');
    });
  });
}
