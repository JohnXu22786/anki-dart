/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:anki_search_parser/anki_search_parser.dart'
    show DueProperty, Property, Search, SearchBuilder, SearchNodeBuilder;

/// Validates the positive, at most five digit Review Ahead input accepted by
/// AnkiDroid's dialog.
void validateReviewAheadDays(int days) {
  if (days < 1) throw ArgumentError.value(days, 'days');
  if (days > 99999) throw RangeError.value(days, 'days');
}

/// Builds the Core search used both for Review Ahead availability and its
/// filtered-study session. Deck names are escaped as structured search nodes.
String buildReviewAheadSearch({required String deckName, required int days}) {
  validateReviewAheadDays(days);
  return SearchBuilder.all([
    SearchNodeBuilder.fromDeckName(deckName),
    Search(Property(operator: '<=', kind: DueProperty(days))),
  ]).write();
}

/// Builds the availability query with the same ineligible-card filters used
/// when the filtered session moves cards.
String buildReviewAheadAvailabilitySearch({
  required String deckName,
  required int days,
}) =>
    '${buildReviewAheadSearch(deckName: deckName, days: days)} '
    '-is:suspended -is:buried -deck:filtered';

/// Search order used by Core's Review Ahead filtered deck configuration.
String buildReviewAheadFilteredSearch({
  required String deckName,
  required int days,
}) {
  validateReviewAheadDays(days);
  return SearchBuilder.all([
    Search(Property(operator: '<=', kind: DueProperty(days))),
    SearchNodeBuilder.fromDeckName(deckName),
  ]).write();
}
