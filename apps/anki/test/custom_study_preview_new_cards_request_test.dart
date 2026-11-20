/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'package:anki_app/custom_study_preview_new_cards_request.dart';
import 'package:anki_backend_protocol/anki/decks.pb.dart' as deck_proto;
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('preview request matches Core filtered session settings', () {
    final id = Int64.parseInt('9007199254740995');
    final request = previewNewCardsFilteredDeckRequest(
      existingSessionId: id,
      deckName: 'Biology',
      days: 7,
    );

    expect(request.id, id);
    expect(request.name, 'Custom Study Session');
    expect(request.allowEmpty, isFalse);
    expect(request.config.reschedule, isFalse);
    expect(
      request.config.searchTerms.single.search,
      'is:new added:7 deck:Biology',
    );
    expect(request.config.searchTerms.single.limit, 99999);
    expect(
      request.config.searchTerms.single.order,
      deck_proto.Deck_Filtered_SearchTerm_Order.ADDED,
    );
  });
}
