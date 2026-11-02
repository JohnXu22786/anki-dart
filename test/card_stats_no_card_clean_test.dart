/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
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
 * Source-derived from Translations.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('cardStatsNoCardClean', () {
    test('matches the pinned documentation example', () {
      expect(
        cardStatsNoCardClean(() => '(No card to display.)'),
        'No card to display',
      );
    });

    test('removes repeated parentheses and periods globally', () {
      expect(cardStatsNoCardClean(() => 'a...((b)))..c'), 'abc');
    });

    test('preserves other content, whitespace, and line breaks', () {
      const original = ' (keep) ñ…\t\r\n(next.) ';

      expect(cardStatsNoCardClean(() => original), ' keep ñ…\t\r\nnext ');
    });

    test('calls the host callback exactly once', () {
      var calls = 0;

      final result = cardStatsNoCardClean(() {
        calls++;
        return '(text.)';
      });

      expect(calls, 1);
      expect(result, 'text');
    });

    test('propagates the host callback exception unchanged', () {
      final failure = StateError('localized text unavailable');

      expect(
        () => cardStatsNoCardClean(() => throw failure),
        throwsA(same(failure)),
      );
    });
  });
}
