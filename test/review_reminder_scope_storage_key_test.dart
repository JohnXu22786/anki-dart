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
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from ReviewRemindersDatabase.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('reviewReminderScopeStorageKey', () {
    test('uses the app-wide key for global scope', () {
      expect(
        reviewReminderScopeStorageKey(const GlobalReminderScope()),
        'app_wide',
      );
    });

    test('appends the deck ID without changing its decimal representation', () {
      for (final deckId in [
        -1,
        0,
        12345,
        -9223372036854775808,
        9223372036854775807,
      ]) {
        expect(
          reviewReminderScopeStorageKey(DeckSpecificReminderScope(deckId)),
          'deck_$deckId',
        );
      }
    });
  });
}
