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
  group('projectBrowserRepositionDueExtrema', () {
    test('maps ordinary extrema to queue bounds', () {
      final bounds = projectBrowserRepositionDueExtrema(minDue: 1, maxDue: 2);

      expect(bounds.queueTop, 1);
      expect(bounds.queueBottom, 2);
    });

    test('clamps negative min due to zero before sorting', () {
      final bounds = projectBrowserRepositionDueExtrema(minDue: -9, maxDue: 6);

      expect(bounds.queueTop, 0);
      expect(bounds.queueBottom, 6);
    });

    test('retains negative max due and sorts it as queue top', () {
      final bounds = projectBrowserRepositionDueExtrema(minDue: 3, maxDue: -4);

      expect(bounds.queueTop, -4);
      expect(bounds.queueBottom, 3);
    });
  });
}
