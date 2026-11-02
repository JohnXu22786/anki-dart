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
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from DeckOptionsDestination.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

/// One optional deck target shown before opening deck options.
class DeckOptionsEntry {
  const DeckOptionsEntry({
    required this.deckId,
    required this.name,
    required this.isFiltered,
  });

  final int deckId;
  final String? name;
  final bool isFiltered;
}

/// Identifies the deck-options screen and optional alternate deck targets.
///
/// [options] is retained by reference and in its supplied order. Collection
/// access and Android Intent behavior remain host-side.
class DeckOptionsDestination {
  const DeckOptionsDestination({
    required this.deckId,
    required this.isFiltered,
    this.options = const [],
  });

  final int deckId;
  final bool isFiltered;
  final List<DeckOptionsEntry> options;

  /// Resolves `decks.isFiltered(deckId)` once and returns this deck destination.
  ///
  /// Host callback failures propagate unchanged.
  static Future<DeckOptionsDestination> fromDeckId({
    required int deckId,
    required DeckOptionsDestinationCollectionCallbacks callbacks,
  }) async {
    final isFiltered = await callbacks.isFiltered(deckId);
    return DeckOptionsDestination(deckId: deckId, isFiltered: isFiltered);
  }

  /// Resolves the current deck ID, then its filtered state, in source order.
  ///
  /// If either host callback fails, the failure propagates unchanged and later
  /// callbacks are not invoked.
  static Future<DeckOptionsDestination> fromCurrentDeck({
    required DeckOptionsDestinationCollectionCallbacks callbacks,
  }) async {
    final deckId = await callbacks.getCurrentDeckId();
    final isFiltered = await callbacks.isFiltered(deckId);
    return DeckOptionsDestination(deckId: deckId, isFiltered: isFiltered);
  }

  /// Delegates to the host builder selected by [isFiltered].
  ///
  /// The same [context] and [deckId] are forwarded once, and the exact host
  /// result is returned. Android Context and Intent behavior remain host-side.
  TIntent toIntent<TContext, TIntent>({
    required TContext context,
    required DeckOptionsDestinationIntentCallbacks<TContext, TIntent> callbacks,
  }) => isFiltered
      ? callbacks.getFilteredDeckOptionsIntent(context, deckId)
      : callbacks.getDeckOptionsIntent(context, deckId);
}

/// Host collection operations needed by the source destination factories.
class DeckOptionsDestinationCollectionCallbacks {
  const DeckOptionsDestinationCollectionCallbacks({
    required this.getCurrentDeckId,
    required this.isFiltered,
  });

  final Future<int> Function() getCurrentDeckId;
  final Future<bool> Function(int deckId) isFiltered;
}

/// Host Intent builders for filtered and ordinary deck-options screens.
class DeckOptionsDestinationIntentCallbacks<TContext, TIntent> {
  const DeckOptionsDestinationIntentCallbacks({
    required this.getFilteredDeckOptionsIntent,
    required this.getDeckOptionsIntent,
  });

  final TIntent Function(TContext context, int deckId)
  getFilteredDeckOptionsIntent;
  final TIntent Function(TContext context, int deckId) getDeckOptionsIntent;
}
