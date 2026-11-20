/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'package:anki_backend_protocol/anki/decks.pb.dart' as deck_proto;
import 'package:anki_dart/anki_dart.dart' show buildPreviewNewCardsSearch;
import 'package:fixnum/fixnum.dart';

/// Builds the non-rescheduling filtered session used for previewing new cards.
deck_proto.FilteredDeckForUpdate previewNewCardsFilteredDeckRequest({
  required Int64 existingSessionId,
  required String deckName,
  required int days,
}) => deck_proto.FilteredDeckForUpdate(
  id: existingSessionId,
  name: 'Custom Study Session',
  config: deck_proto.Deck_Filtered(reschedule: false)
    ..searchTerms.add(
      deck_proto.Deck_Filtered_SearchTerm(
        search: buildPreviewNewCardsSearch(deckName: deckName, days: days),
        limit: 99999,
        order: deck_proto.Deck_Filtered_SearchTerm_Order.ADDED,
      ),
    ),
  allowEmpty: false,
);
