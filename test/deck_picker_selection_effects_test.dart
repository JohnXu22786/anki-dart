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
 * Source-derived from DeckPickerViewModel.kt:273–323 in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  test(
    'selection orders collection select, focus update, then list refresh',
    () {
      final deckId = 23;
      final plan = planDeckPickerSelection(deckId);

      expect(plan.selectionEffects, hasLength(3));
      final select = plan.selectionEffects[0] as DeckPickerSelectDeck;
      final focus = plan.selectionEffects[1] as DeckPickerSetFocusedDeck;
      expect(select.deckId, deckId);
      expect(focus.deckId, deckId);
      expect(plan.selectionEffects[2], isA<DeckPickerRefreshDeckList>());
      expect(plan.menuPublication, isNull);
    },
  );

  test(
    'context menu payload follows the selection join and retains deck ID',
    () {
      final deckId = 41;
      final plan = planDeckPickerContextMenu(deckId);

      expect(plan.selectionEffects, hasLength(3));
      expect(plan.selectionEffects[0], isA<DeckPickerSelectDeck>());
      expect(plan.selectionEffects[1], isA<DeckPickerSetFocusedDeck>());
      expect(plan.selectionEffects[2], isA<DeckPickerRefreshDeckList>());
      final publish = plan.menuPublication as DeckPickerPublishContextMenu;
      expect(publish.deckId, deckId);
    },
  );

  test(
    'right-click payload retains ID and exact coordinates after selection join',
    () {
      const x = 17.25;
      const y = -3.5;
      final plan = planDeckPickerRightClickContextMenu(deckId: 58, x: x, y: y);

      expect(plan.selectionEffects, hasLength(3));
      expect(plan.selectionEffects[0], isA<DeckPickerSelectDeck>());
      expect(plan.selectionEffects[1], isA<DeckPickerSetFocusedDeck>());
      expect(plan.selectionEffects[2], isA<DeckPickerRefreshDeckList>());
      final publish =
          plan.menuPublication as DeckPickerPublishRightClickContextMenu;
      expect(publish.deckId, 58);
      expect(publish.x, x);
      expect(publish.y, y);
    },
  );
}
