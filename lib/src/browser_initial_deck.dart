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
 * Behavioral reference: CardBrowserViewModel.getInitialDeck() in AnkiDroid
 * 2.25.3; see ANKIDROID_UPSTREAM.md. Android state and deck lookup stay host-side.
 */

/// The selected-deck value returned by the host for the current collection.
sealed class BrowserInitialDeckSelection {
  const BrowserInitialDeckSelection();
}

/// Represents the source's `SelectableDeck.AllDecks` choice.
final class BrowserAllDecksSelection extends BrowserInitialDeckSelection {
  const BrowserAllDecksSelection();
}

/// A host-resolved deck ID and name.
final class BrowserDeckSelection extends BrowserInitialDeckSelection {
  const BrowserDeckSelection(this.id, this.name);

  final int id;
  final String name;
}

/// The ordered result of projecting the initial selected-deck resolution.
final class BrowserInitialDeckPlan {
  const BrowserInitialDeckPlan({
    required this.consumeLaunchIntent,
    required this.selectedDeck,
  });

  /// True when the host must mark the launch intent consumed in saved state.
  ///
  /// The source writes this before checking whether its ID or deck name exists.
  final bool consumeLaunchIntent;

  /// The source-selected deck after the host has supplied valid resolutions.
  final BrowserInitialDeckSelection selectedDeck;
}

/// Projects `CardBrowserViewModel.getInitialDeck()` using host-resolved values.
///
/// [intentDeck] is the host-resolved launch deck, or null when its ID is absent,
/// unknown, or already consumed. A non-null value wins only when
/// [launchIntentConsumed] is false. The host must persist the consumption
/// transition before resolving the intent ID or name. [validLastDeck] is
/// non-null only when the host confirms that [lastDeckId] still exists. The
/// current selected deck is already resolved by the host. This function
/// performs no Android state access or collection IO.
BrowserInitialDeckPlan planBrowserInitialDeck({
  required bool launchIntentConsumed,
  required BrowserDeckSelection? intentDeck,
  required int? lastDeckId,
  required int allDecksId,
  required BrowserDeckSelection? validLastDeck,
  required BrowserDeckSelection currentSelectedDeck,
}) {
  final consumeLaunchIntent = !launchIntentConsumed;
  if (consumeLaunchIntent && intentDeck != null) {
    return BrowserInitialDeckPlan(
      consumeLaunchIntent: true,
      selectedDeck: intentDeck,
    );
  }

  if (lastDeckId == allDecksId) {
    return BrowserInitialDeckPlan(
      consumeLaunchIntent: consumeLaunchIntent,
      selectedDeck: const BrowserAllDecksSelection(),
    );
  }

  if (lastDeckId != null && validLastDeck != null) {
    return BrowserInitialDeckPlan(
      consumeLaunchIntent: consumeLaunchIntent,
      selectedDeck: validLastDeck,
    );
  }

  return BrowserInitialDeckPlan(
    consumeLaunchIntent: consumeLaunchIntent,
    selectedDeck: currentSelectedDeck,
  );
}
