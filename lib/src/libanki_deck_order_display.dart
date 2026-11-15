/*
 * Copyright (c) 2020 Arthur Milchior <arthur@milchior.fr>
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
 * SPDX-FileCopyrightText: 2020 Arthur Milchior <arthur@milchior.fr>
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from Deck.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

/// Filtered-deck card order accepted by `Deck.Order.toDisplayString`.
///
/// The generated protobuf enum remains host-owned; this type carries only the
/// source cases needed by the portable display mapping.
enum LibAnkiDeckOrder {
  oldestReviewedFirst,
  random,
  intervalsAscending,
  intervalsDescending,
  lapses,
  added,
  due,
  reverseAdded,
  retrievabilityAscending,
  retrievabilityDescending,
  relativeOverdueness,
  unrecognized,
}

/// Host translations used by [libAnkiDeckOrderToDisplayString].
///
/// The host retains its generated `Translations` implementation and provides
/// only the callbacks needed for the selected order.
final class LibAnkiDeckOrderDisplayTranslations {
  const LibAnkiDeckOrderDisplayTranslations({
    required this.decksOldestSeenFirst,
    required this.decksRandom,
    required this.decksIncreasingIntervals,
    required this.decksDecreasingIntervals,
    required this.decksMostLapses,
    required this.decksOrderAdded,
    required this.decksOrderDue,
    required this.decksLatestAddedFirst,
    required this.deckConfigSortOrderRetrievabilityAscending,
    required this.deckConfigSortOrderRetrievabilityDescending,
    required this.decksRelativeOverdueness,
  });

  final String Function() decksOldestSeenFirst;
  final String Function() decksRandom;
  final String Function() decksIncreasingIntervals;
  final String Function() decksDecreasingIntervals;
  final String Function() decksMostLapses;
  final String Function() decksOrderAdded;
  final String Function() decksOrderDue;
  final String Function() decksLatestAddedFirst;
  final String Function() deckConfigSortOrderRetrievabilityAscending;
  final String Function() deckConfigSortOrderRetrievabilityDescending;
  final String Function() decksRelativeOverdueness;
}

/// Returns the source translation for [order].
///
/// Exactly one host translation callback runs for a recognized order. Callback
/// failures propagate unchanged. The generated enum and translations remain
/// host-owned; callers adapt their values at this boundary.
String libAnkiDeckOrderToDisplayString({
  required LibAnkiDeckOrder order,
  required LibAnkiDeckOrderDisplayTranslations translations,
}) => switch (order) {
  LibAnkiDeckOrder.oldestReviewedFirst => translations.decksOldestSeenFirst(),
  LibAnkiDeckOrder.random => translations.decksRandom(),
  LibAnkiDeckOrder.intervalsAscending =>
    translations.decksIncreasingIntervals(),
  LibAnkiDeckOrder.intervalsDescending =>
    translations.decksDecreasingIntervals(),
  LibAnkiDeckOrder.lapses => translations.decksMostLapses(),
  LibAnkiDeckOrder.added => translations.decksOrderAdded(),
  LibAnkiDeckOrder.due => translations.decksOrderDue(),
  LibAnkiDeckOrder.reverseAdded => translations.decksLatestAddedFirst(),
  LibAnkiDeckOrder.retrievabilityAscending =>
    translations.deckConfigSortOrderRetrievabilityAscending(),
  LibAnkiDeckOrder.retrievabilityDescending =>
    translations.deckConfigSortOrderRetrievabilityDescending(),
  LibAnkiDeckOrder.relativeOverdueness =>
    translations.decksRelativeOverdueness(),
  LibAnkiDeckOrder.unrecognized => throw ArgumentError(
    "Can't display an unknown enum value.",
  ),
};
