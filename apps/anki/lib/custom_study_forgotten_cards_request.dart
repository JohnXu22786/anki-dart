/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:anki_backend_protocol/anki/decks.pb.dart' as deck_proto;
import 'package:anki_dart/anki_dart.dart'
    show buildForgottenCardsFilteredSearch;
import 'package:fixnum/fixnum.dart';

/// Builds Core's forgotten-card Custom Study filtered-deck configuration.
deck_proto.FilteredDeckForUpdate forgottenCardsFilteredDeckRequest({
  required Int64 existingSessionId,
  required String deckName,
  required int days,
}) => deck_proto.FilteredDeckForUpdate(
  id: existingSessionId,
  name: 'Custom Study Session',
  config: deck_proto.Deck_Filtered(reschedule: false)
    ..searchTerms.add(
      deck_proto.Deck_Filtered_SearchTerm(
        search: buildForgottenCardsFilteredSearch(
          deckName: deckName,
          days: days,
        ),
        limit: 99999,
        order: deck_proto.Deck_Filtered_SearchTerm_Order.RANDOM,
      ),
    ),
  allowEmpty: false,
);
