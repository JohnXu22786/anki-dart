/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from DeckPickerViewModel.kt:435–452 and DeckNode.kt in
 * AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  test(
    'toggle resolves first depth-first match and orders mutation, persistence, refresh',
    () {
      final firstMatch = DeckNode(
        did: 17,
        fullDeckName: 'first',
        depth: 0,
        collapsed: false,
      );
      final laterMatch = DeckNode(
        did: 17,
        fullDeckName: 'later',
        depth: 0,
        collapsed: true,
      );
      final tree = DeckNode.syntheticRoot(
        children: [
          DeckNode(
            did: 3,
            fullDeckName: 'parent',
            depth: 0,
            children: [firstMatch],
          ),
          laterMatch,
        ],
      );

      final plan = planDeckPickerExpandToggle(tree, 17);

      expect(plan.target, same(firstMatch));
      expect(plan.wasCollapsed, isFalse);
      expect(plan.collapsed, isTrue);
      expect(firstMatch.collapsed, isFalse);
      expect(laterMatch.collapsed, isTrue);
      expect(plan.effects.map((effect) => effect.runtimeType), [
        SetDeckNodeCollapsedEffect,
        PersistDeckCollapsedEffect,
        RefreshDeckListAfterExpandToggleEffect,
      ]);
      final mutate = plan.effects[0] as SetDeckNodeCollapsedEffect;
      expect(mutate.node, same(firstMatch));
      expect(mutate.collapsed, isTrue);
      final persist = plan.effects[1] as PersistDeckCollapsedEffect;
      expect(persist.deckId, 17);
      expect(persist.collapsed, isTrue);
      expect(persist.scope, DeckPickerDeckCollapseScope.reviewer);

      final collapsePlan = planDeckPickerExpandToggle(
        DeckNode.syntheticRoot(children: [laterMatch]),
        17,
      );
      expect(collapsePlan.wasCollapsed, isTrue);
      expect(collapsePlan.collapsed, isFalse);
      expect(
        (collapsePlan.effects[1] as PersistDeckCollapsedEffect).collapsed,
        isFalse,
      );
      expect(laterMatch.collapsed, isTrue);
    },
  );

  test('missing tree or target still emits only deck-list refresh', () {
    final tree = DeckNode.syntheticRoot(
      children: [DeckNode(did: 2, fullDeckName: 'other', depth: 0)],
    );

    for (final plan in [
      planDeckPickerExpandToggle(null, 17),
      planDeckPickerExpandToggle(tree, 17),
    ]) {
      expect(plan.target, isNull);
      expect(plan.wasCollapsed, isNull);
      expect(plan.collapsed, isNull);
      expect(plan.effects, hasLength(1));
      expect(
        plan.effects.single,
        isA<RefreshDeckListAfterExpandToggleEffect>(),
      );
    }
  });
}
