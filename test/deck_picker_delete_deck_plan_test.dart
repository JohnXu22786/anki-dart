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
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived DeckPicker cases; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  test('deletes one deck, resets focus, then publishes its name and count', () {
    final plan = planDeckPickerDeleteDeck(
      deckId: 73,
      deckName: 'Parent::Child',
      cardsDeleted: 12,
    );

    expect(plan.effects, hasLength(3));
    final removal = plan.effects[0] as DeckPickerRemoveDecks;
    expect(removal.deckIds, [73]);
    expect(plan.effects[1], isA<DeckPickerSetDefaultFocusedDeck>());
    final notification = plan.effects[2] as DeckPickerPublishDeckDeletionResult;
    expect(notification.deckName, 'Parent::Child');
    expect(notification.cardsDeleted, 12);
  });
}
