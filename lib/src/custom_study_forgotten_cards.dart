/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:anki_search_parser/anki_search_parser.dart'
    show AnswerButton, Rated, Search, SearchBuilder, SearchNodeBuilder;

/// AnkiDroid parses the value as a signed 32-bit integer; Core stores it as
/// uint32, so the source dialog's positive input range is 1..INT32_MAX.
void validateForgottenCardsDays(int days) {
  if (days < 1) throw ArgumentError.value(days, 'days');
  if (days > 0x7fffffff) throw RangeError.value(days, 'days');
}

/// Core's forgotten-card search: answered Again within [days] days in [deckName].
String buildForgottenCardsSearch({
  required String deckName,
  required int days,
}) {
  validateForgottenCardsDays(days);
  return SearchBuilder.all([
    SearchNodeBuilder.fromDeckName(deckName),
    Search(Rated(days: days, ease: const AnswerButton(1))),
  ]).write();
}

/// Availability query also excludes cards that cannot enter a filtered deck.
String buildForgottenCardsAvailabilitySearch({
  required String deckName,
  required int days,
}) =>
    '${buildForgottenCardsSearch(deckName: deckName, days: days)} '
    '-is:suspended -is:buried -deck:filtered';

/// Core's filtered-deck search term order places the rating predicate first.
String buildForgottenCardsFilteredSearch({
  required String deckName,
  required int days,
}) {
  validateForgottenCardsDays(days);
  return SearchBuilder.all([
    Search(Rated(days: days, ease: const AnswerButton(1))),
    SearchNodeBuilder.fromDeckName(deckName),
  ]).write();
}
