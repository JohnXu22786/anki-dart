/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
 * Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived cases for CardBrowserViewModel.refreshColumnsFromPrefs();
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Card Browser refresh columns from preferences', () {
    test('incomplete initialization requests neither loading nor updating', () {
      final plan = planBrowserRefreshColumnsFromPrefs(
        initCompleted: false,
        activeColumns: [BrowserColumn.question],
      );

      expect(plan.shouldLoadPreferences, isFalse);
      expect(plan.shouldUpdateActiveColumns, isFalse);
    });

    test('initialized host requests preference loading before comparing', () {
      final plan = planBrowserRefreshColumnsFromPrefs(
        initCompleted: true,
        activeColumns: [BrowserColumn.question],
      );

      expect(plan.shouldLoadPreferences, isTrue);
      expect(plan.shouldUpdateActiveColumns, isFalse);
    });

    test('equal ordered loaded columns do not request an update', () {
      final plan = planBrowserRefreshColumnsFromPrefs(
        initCompleted: true,
        activeColumns: [BrowserColumn.question, BrowserColumn.deck],
        storedColumns: [BrowserColumn.question, BrowserColumn.deck],
      );

      expect(plan.shouldLoadPreferences, isFalse);
      expect(plan.shouldUpdateActiveColumns, isFalse);
    });

    test('changed ordered loaded columns request update with stored order', () {
      final storedColumns = [BrowserColumn.deck, BrowserColumn.question];
      final plan = planBrowserRefreshColumnsFromPrefs(
        initCompleted: true,
        activeColumns: [BrowserColumn.question, BrowserColumn.deck],
        storedColumns: storedColumns,
      );

      expect(plan.shouldLoadPreferences, isFalse);
      expect(plan.shouldUpdateActiveColumns, isTrue);
      expect(plan.columnsToUpdate, storedColumns);
    });
  });
}
