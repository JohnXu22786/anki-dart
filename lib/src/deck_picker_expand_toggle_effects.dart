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
 * Behavioral reference: `toggleDeckExpand` in DeckPickerViewModel.kt,
 * AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'deck_node.dart';

/// Persistence scope passed to AnkiDroid's `decks.setCollapsed` call.
enum DeckPickerDeckCollapseScope { reviewer }

/// One ordered host operation in a deck expansion toggle.
sealed class DeckPickerExpandToggleEffect {
  const DeckPickerExpandToggleEffect();
}

/// The host mutates [node].collapsed to [collapsed].
final class SetDeckNodeCollapsedEffect extends DeckPickerExpandToggleEffect {
  const SetDeckNodeCollapsedEffect({
    required this.node,
    required this.collapsed,
  });

  final DeckNode node;
  final bool collapsed;
}

/// The host calls `decks.setCollapsed` with this value and [scope].
final class PersistDeckCollapsedEffect extends DeckPickerExpandToggleEffect {
  const PersistDeckCollapsedEffect({
    required this.deckId,
    required this.collapsed,
    required this.scope,
  });

  final int deckId;
  final bool collapsed;
  final DeckPickerDeckCollapseScope scope;
}

/// The host emits one deck-list refresh request.
final class RefreshDeckListAfterExpandToggleEffect
    extends DeckPickerExpandToggleEffect {
  const RefreshDeckListAfterExpandToggleEffect();
}

/// Immutable target and ordered host effects for `toggleDeckExpand`.
///
/// The host applies [effects] sequentially. If node mutation or persistence
/// fails, normal host exception behavior stops later effects, including refresh.
final class DeckPickerExpandTogglePlan {
  DeckPickerExpandTogglePlan({
    required this.target,
    required this.wasCollapsed,
    required this.collapsed,
    required Iterable<DeckPickerExpandToggleEffect> effects,
  }) : effects = List.unmodifiable(effects);

  final DeckNode? target;
  final bool? wasCollapsed;
  final bool? collapsed;

  /// Effects in the order the host must apply them.
  final List<DeckPickerExpandToggleEffect> effects;
}

/// Projects AnkiDroid's in-memory toggle, REVIEWER persistence, and refresh.
///
/// Lookup uses [DeckNode.find]'s first depth-first match. A missing tree or deck
/// skips mutation and persistence but still requests a deck-list refresh. This
/// projection does not mutate the target; the host owns the coroutine,
/// collection call, flow emission, and UI.
DeckPickerExpandTogglePlan planDeckPickerExpandToggle(
  DeckNode? dueTree,
  int deckId,
) {
  final target = dueTree?.find(deckId);
  if (target == null) {
    return DeckPickerExpandTogglePlan(
      target: null,
      wasCollapsed: null,
      collapsed: null,
      effects: const [RefreshDeckListAfterExpandToggleEffect()],
    );
  }

  final wasCollapsed = target.collapsed;
  final collapsed = !wasCollapsed;
  return DeckPickerExpandTogglePlan(
    target: target,
    wasCollapsed: wasCollapsed,
    collapsed: collapsed,
    effects: [
      SetDeckNodeCollapsedEffect(node: target, collapsed: collapsed),
      PersistDeckCollapsedEffect(
        deckId: target.did,
        collapsed: collapsed,
        scope: DeckPickerDeckCollapseScope.reviewer,
      ),
      const RefreshDeckListAfterExpandToggleEffect(),
    ],
  );
}
