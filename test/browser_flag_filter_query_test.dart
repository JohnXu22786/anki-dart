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
 * Behavioral reference: CardBrowserViewModel.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('browserSearchTermsWithFlag', () {
    test('uses the supplied source flag codes directly', () {
      for (var code = 0; code <= 7; code++) {
        expect(
          browserSearchTermsWithFlag(searchTerms: '', flagCode: code),
          'flag:$code',
        );
      }
    });

    test('prepends one flag term to a nonempty query', () {
      expect(
        browserSearchTermsWithFlag(
          searchTerms: 'is:new deck:Current',
          flagCode: 1,
        ),
        'flag:1 is:new deck:Current',
      );
    });

    test('whitespace-only existing terms are preserved after the new term', () {
      expect(
        browserSearchTermsWithFlag(searchTerms: ' \t ', flagCode: 2),
        'flag:2  \t ',
      );
    });

    test('replaces the first unanchored flag match and preserves later matches',
        () {
      expect(
        browserSearchTermsWithFlag(
          searchTerms: 'someflag:3 flag:4 is:new',
          flagCode: 7,
        ),
        'someflag:7 flag:4 is:new',
      );
    });

    test('consumes exactly one character after the first flag prefix', () {
      expect(
        browserSearchTermsWithFlag(searchTerms: 'flag:12', flagCode: 7),
        'flag:72',
      );
    });

    test('contains without a regex match leaves the original query unchanged',
        () {
      for (final suffix in ['', '\n', '\r', '\u0085', '\u2028', '\u2029']) {
        final query = 'flag:$suffix';
        expect(
          browserSearchTermsWithFlag(searchTerms: query, flagCode: 4),
          query,
        );
      }
    });

    test('the first match can follow an incomplete line-terminated prefix', () {
      expect(
        browserSearchTermsWithFlag(
          searchTerms: 'flag:\n flag:2',
          flagCode: 5,
        ),
        'flag:\n flag:5',
      );
    });

    test('uppercase prefix does not count as the source lowercase marker', () {
      expect(
        browserSearchTermsWithFlag(searchTerms: 'FLAG:4', flagCode: 3),
        'flag:3 FLAG:4',
      );
    });

    test('a Unicode supplementary character is replaced as one regex dot', () {
      expect(
        browserSearchTermsWithFlag(
          searchTerms: 'flag:🐈 is:new',
          flagCode: 6,
        ),
        'flag:6 is:new',
      );
    });
  });
}
