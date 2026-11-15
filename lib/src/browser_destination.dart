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
 * Source-derived from BrowserDestination.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

/// Host operations used by `BrowserDestination.toIntent(context)`.
///
/// The host supplies Android Context and Intent behavior, including the
/// `CardBrowser` target and extra keys.
class BrowserDestinationIntentCallbacks<TContext, TIntent, TTarget> {
  const BrowserDestinationIntentCallbacks({
    required this.createIntent,
    required this.putLongExtra,
    required this.putStringExtra,
    required this.putBooleanExtra,
  });

  final TIntent Function(TContext context, TTarget target) createIntent;
  final void Function(TIntent intent, String key, int value) putLongExtra;
  final void Function(TIntent intent, String key, String value) putStringExtra;
  final void Function(TIntent intent, String key, bool value) putBooleanExtra;
}

/// The source `BrowserDestination` choices for opening and searching the
/// Card Browser.
sealed class BrowserDestination {
  const BrowserDestination();

  /// Opens the Card Browser without adding extras.
  static const BrowserDestination open = BrowserDestinationOpen._();

  /// Opens the Card Browser scoped to the exact [deckId].
  static BrowserDestinationToDeck toDeck(int deckId) =>
      BrowserDestinationToDeck(deckId);

  /// Opens the Card Browser scoped to [deckId] and positioned at [cardId].
  static BrowserDestinationScrollToCard scrollToCard(int deckId, int cardId) =>
      BrowserDestinationScrollToCard(deckId, cardId);

  /// Opens the Card Browser with the exact [query] and [allDecks] setting.
  static BrowserDestinationSearch search(String query, bool allDecks) =>
      BrowserDestinationSearch(query, allDecks);

  /// Adapts `BrowserDestination.toIntent(context)`.
  ///
  /// Every branch creates one host Intent. The selected branch writes its
  /// source extras in source order and returns that same Intent. Values and
  /// callback failures pass through unchanged; a failure stops later writes.
  /// Android Context, Intent keys and semantics remain host-side.
  TIntent toIntent<TContext, TIntent, TTarget>({
    required TContext context,
    required TTarget cardBrowserTarget,
    required String deckIdExtraKey,
    required String cardIdExtraKey,
    required String searchQueryExtraKey,
    required String allDecksExtraKey,
    required BrowserDestinationIntentCallbacks<TContext, TIntent, TTarget>
    callbacks,
  }) {
    switch (this) {
      case BrowserDestinationOpen():
        return callbacks.createIntent(context, cardBrowserTarget);
      case BrowserDestinationToDeck(:final deckId):
        final intent = callbacks.createIntent(context, cardBrowserTarget);
        callbacks.putLongExtra(intent, deckIdExtraKey, deckId);
        return intent;
      case BrowserDestinationScrollToCard(:final deckId, :final cardId):
        final intent = callbacks.createIntent(context, cardBrowserTarget);
        callbacks.putLongExtra(intent, deckIdExtraKey, deckId);
        callbacks.putLongExtra(intent, cardIdExtraKey, cardId);
        return intent;
      case BrowserDestinationSearch(:final query, :final allDecks):
        final intent = callbacks.createIntent(context, cardBrowserTarget);
        callbacks.putStringExtra(intent, searchQueryExtraKey, query);
        callbacks.putBooleanExtra(intent, allDecksExtraKey, allDecks);
        return intent;
    }
  }
}

/// Source `Open` singleton.
final class BrowserDestinationOpen extends BrowserDestination {
  const BrowserDestinationOpen._();
}

/// Source `ToDeck(deckId)` variant, preserving its exact ID.
final class BrowserDestinationToDeck extends BrowserDestination {
  const BrowserDestinationToDeck(this.deckId);

  final int deckId;

  @override
  bool operator ==(Object other) =>
      other is BrowserDestinationToDeck && other.deckId == deckId;

  @override
  int get hashCode => Object.hash(BrowserDestinationToDeck, deckId);
}

/// Source `ScrollToCard(deckId, cardId)` variant, preserving both IDs.
final class BrowserDestinationScrollToCard extends BrowserDestination {
  const BrowserDestinationScrollToCard(this.deckId, this.cardId);

  final int deckId;
  final int cardId;

  @override
  bool operator ==(Object other) =>
      other is BrowserDestinationScrollToCard &&
      other.deckId == deckId &&
      other.cardId == cardId;

  @override
  int get hashCode =>
      Object.hash(BrowserDestinationScrollToCard, deckId, cardId);
}

/// Source `Search(query, allDecks)` variant, preserving both values.
final class BrowserDestinationSearch extends BrowserDestination {
  const BrowserDestinationSearch(this.query, this.allDecks);

  final String query;
  final bool allDecks;

  @override
  bool operator ==(Object other) =>
      other is BrowserDestinationSearch &&
      other.query == query &&
      other.allDecks == allDecks;

  @override
  int get hashCode => Object.hash(BrowserDestinationSearch, query, allDecks);
}
