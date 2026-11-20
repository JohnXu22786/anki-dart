/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'package:anki_backend_protocol/anki/decks.pb.dart' as deck_proto;
import 'package:anki_dart/anki_dart.dart' show buildReviewAheadFilteredSearch;
import 'package:fixnum/fixnum.dart';

/// Creates the collection builder request corresponding to Core's
/// `ahead_config()` and `create_custom_study_deck()` behavior.
deck_proto.FilteredDeckForUpdate reviewAheadFilteredDeckRequest({
  required Int64 existingSessionId,
  required String deckName,
  required int days,
}) => deck_proto.FilteredDeckForUpdate(
  id: existingSessionId,
  name: 'Custom Study Session',
  config: deck_proto.Deck_Filtered(reschedule: true)
    ..searchTerms.add(
      deck_proto.Deck_Filtered_SearchTerm(
        search: buildReviewAheadFilteredSearch(deckName: deckName, days: days),
        limit: 99999,
        order: deck_proto.Deck_Filtered_SearchTerm_Order.DUE,
      ),
    ),
  allowEmpty: false,
);
