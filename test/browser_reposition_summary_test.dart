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
  group('projectBrowserRepositionSummary', () {
    test('joins host-localized lines with one literal newline', () {
      expect(
        projectBrowserRepositionSummary(
          queueTop: 1,
          queueBottom: 2,
          formattedTopLine: 'Queue top: \u20681\u2069',
          formattedBottomLine: 'Queue bottom: \u20682\u2069',
        ),
        'Queue top: \u20681\u2069\nQueue bottom: \u20682\u2069',
      );
    });

    test('missing top bound returns null', () {
      expect(
        projectBrowserRepositionSummary(
          queueTop: null,
          queueBottom: 2,
          formattedTopLine: 'top',
          formattedBottomLine: 'bottom',
        ),
        isNull,
      );
    });

    test('missing bottom bound returns null', () {
      expect(
        projectBrowserRepositionSummary(
          queueTop: 1,
          queueBottom: null,
          formattedTopLine: 'top',
          formattedBottomLine: 'bottom',
        ),
        isNull,
      );
    });
  });
}
