/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from AnkiDroid 2.25.3 CardBrowserViewModel.kt; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Card Browser active-column update decision', () {
    test('empty columns reject before persistence or flow update', () {
      final plan = planBrowserActiveColumnUpdate(
        currentActiveColumns: [BrowserColumn.question],
        requestedColumns: const [],
        currentMode: BrowserColumnMode.cards,
        targetMode: BrowserColumnMode.cards,
      );

      expect(plan.returnedValue, isFalse);
      expect(plan.shouldPersist, isFalse);
      expect(plan.shouldUpdateActiveFlow, isFalse);
    });

    test('equal columns reject even when targeting the non-active mode', () {
      final plan = planBrowserActiveColumnUpdate(
        currentActiveColumns: [BrowserColumn.question, BrowserColumn.deck],
        requestedColumns: [BrowserColumn.question, BrowserColumn.deck],
        currentMode: BrowserColumnMode.cards,
        targetMode: BrowserColumnMode.notes,
      );

      expect(plan.returnedValue, isFalse);
      expect(plan.shouldPersist, isFalse);
      expect(plan.shouldUpdateActiveFlow, isFalse);
    });

    test('changed active-mode columns persist and request flow update', () {
      final plan = planBrowserActiveColumnUpdate(
        currentActiveColumns: [BrowserColumn.question],
        requestedColumns: [BrowserColumn.question, BrowserColumn.deck],
        currentMode: BrowserColumnMode.cards,
        targetMode: BrowserColumnMode.cards,
      );

      expect(plan.returnedValue, isTrue);
      expect(plan.shouldPersist, isTrue);
      expect(plan.shouldUpdateActiveFlow, isTrue);
    });

    test('changed other-mode columns persist without flow update', () {
      final plan = planBrowserActiveColumnUpdate(
        currentActiveColumns: [BrowserColumn.question],
        requestedColumns: [BrowserColumn.question, BrowserColumn.deck],
        currentMode: BrowserColumnMode.cards,
        targetMode: BrowserColumnMode.notes,
      );

      expect(plan.returnedValue, isTrue);
      expect(plan.shouldPersist, isTrue);
      expect(plan.shouldUpdateActiveFlow, isFalse);
    });
  });
}
