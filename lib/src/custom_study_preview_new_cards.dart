/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:anki_search_parser/anki_search_parser.dart'
    show
        AddedInDays,
        Search,
        SearchBuilder,
        SearchNodeBuilder,
        State,
        StateKind;

/// Validates Preview New Cards days as accepted by AnkiDroid's signed Int input.
void validatePreviewNewCardsDays(int days) {
  if (days < 1) throw ArgumentError.value(days, 'days');
  if (days > 0x7fffffff) throw RangeError.value(days, 'days');
}

/// Builds Core's preview query for new cards added in [days] in [deckName].
String buildPreviewNewCardsSearch({
  required String deckName,
  required int days,
}) {
  validatePreviewNewCardsDays(days);
  return SearchBuilder.all([
    Search(State(StateKind.newCard)),
    Search(AddedInDays(days)),
    SearchNodeBuilder.fromDeckName(deckName),
  ]).write();
}
