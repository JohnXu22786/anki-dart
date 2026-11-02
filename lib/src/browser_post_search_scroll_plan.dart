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
 * Behavioral reference: CardBrowserViewModel.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md. The host performs search synchronization, card
 * lookup, card-to-row mapping, and scroll delivery.
 */

import 'browser_row_collection.dart';
import 'browser_row_selection.dart';

/// An ordered host operation in the post-search initial scroll sequence.
sealed class BrowserPostSearchScrollEffect {
  const BrowserPostSearchScrollEffect();
}

/// Clears the pending target before the host attempts collection lookup.
final class ClearBrowserScrollTarget extends BrowserPostSearchScrollEffect {
  const ClearBrowserScrollTarget();
}

/// Looks up [cardId] in the host collection after clearing the pending target.
final class LookupBrowserScrollTarget extends BrowserPostSearchScrollEffect {
  const LookupBrowserScrollTarget(this.cardId);

  final int cardId;
}

/// Emits [selection] to the host's row-scroll request flow.
final class RequestBrowserRowScroll extends BrowserPostSearchScrollEffect {
  const RequestBrowserRowScroll(this.selection);

  final BrowserRowSelection selection;
}

/// The ordered effects for consuming an initial Card Browser scroll target.
final class BrowserPostSearchScrollPlan {
  BrowserPostSearchScrollPlan._({
    required this.targetCardId,
    required Iterable<BrowserPostSearchScrollEffect> effects,
  }) : effects = List.unmodifiable(effects);

  final int? targetCardId;
  final List<BrowserPostSearchScrollEffect> effects;
}

/// Plans the clear-then-lookup phase for a pending Card Browser scroll target.
///
/// The host reads its pending target and returns when it is absent. For a
/// target, it waits for search completion and consumes these effects in order.
/// It clears the pending target before doing the collection lookup.
BrowserPostSearchScrollPlan planBrowserPostSearchScroll({
  required int? targetCardId,
}) => BrowserPostSearchScrollPlan._(
  targetCardId: targetCardId,
  effects: targetCardId == null
      ? const []
      : [
          const ClearBrowserScrollTarget(),
          LookupBrowserScrollTarget(targetCardId),
        ],
);

/// Completes a clear-then-lookup plan with the host-resolved row ID.
///
/// Call this only after the host has executed [plan]'s clear and lookup effects.
/// A null [resolvedRowId] means the card was no longer found and adds no scroll
/// request. A non-null ID is already mapped by the host for Cards or Notes mode
/// and is passed through unchanged with a zero top offset. Search synchronization,
/// collection access, Cards/Notes conversion, flow emission, and RecyclerView
/// application remain host responsibilities.
BrowserPostSearchScrollPlan completeBrowserPostSearchScrollPlan({
  required BrowserPostSearchScrollPlan plan,
  required int? resolvedRowId,
}) {
  if (plan.targetCardId == null || resolvedRowId == null) {
    return plan;
  }

  return BrowserPostSearchScrollPlan._(
    targetCardId: plan.targetCardId,
    effects: [
      ...plan.effects,
      RequestBrowserRowScroll(
        BrowserRowSelection(rowId: BrowserRowId(resolvedRowId), topOffset: 0),
      ),
    ],
  );
}
